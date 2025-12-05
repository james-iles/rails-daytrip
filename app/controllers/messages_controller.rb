class MessagesController < ApplicationController
  def create
    @chat = current_user.chats.find(params[:chat_id])
    @city = @chat.city
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      system_prompt = build_system_prompt(@city)
      @ruby_llm_chat = RubyLLM.chat
      build_conversation_history

      if @message.content.present?
        user_input = "Additional things to consider: #{@message.content}"
      else
        user_input = "No additional considerations"
      end

      # Get AI response
      response = @ruby_llm_chat.with_instructions(system_prompt).ask(user_input)

      # Enhance with Google Photos
      enhanced_response = enhance_with_google_photos(response.content, @city)

      Message.create!(role: "assistant", content: enhanced_response, chat: @chat)

      @city.update(itinerary: enhanced_response)
      @chat.generate_title_from_first_message

      #respond to turbo stream requests
      respond_to do |format|
          format.turbo_stream # renders `app/views/messages/create.turbo_stream.erb`
          format.html { redirect_to chat_path(@chat) }
        end

    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("new_message", partial: "messages/form", locals: { chat: @chat, message: @message }) }
        format.html { render "chats/show", status: :unprocessable_entity }
    end
  end
end
  private

  def build_system_prompt(city)
    # Handle filters as array
    filters = []
    filters << city.preferences if city.preferences.present?
    filters << city.filters if city.filters.present?

    filters_text = filters.compact.join(", ")
    filters_text = "general sightseeing and local experiences" if filters_text.blank?

    # Format date for the prompt
    date_info = if city.date.present?
      trip_date = city.date.is_a?(String) ? Date.parse(city.date) : city.date
      "- Trip Date: #{trip_date.strftime('%A, %B %d, %Y')} (#{trip_date.strftime('%B %Y')})"
    else
      "- Trip Date: Not specified (suggest activities available year-round)"
    end

    <<~PROMPT
      You are a Local Travel Expert specializing in #{city.name}.

      USER PROFILE:
      - Destination: #{city.name}
      #{date_info}
      - Interests: #{filters_text}

      TASK:
      Create a personalized day trip itinerary for #{city.name} that matches these specific interests and is appropriate for the travel date.

      **DATE-SPECIFIC CONSIDERATIONS:**
      #{if city.date.present?
        trip_date = city.date.is_a?(String) ? Date.parse(city.date) : city.date
        "- Consider weather and seasonal conditions for #{trip_date.strftime('%B')} in #{city.name}
      - Mention if any recommendations have seasonal variations or special hours
      - Suggest appropriate clothing or preparations for the season"
      else
        "- Focus on year-round attractions and activities"
      end}

      **CRITICAL INSTRUCTIONS:**
      1. Provide exactly 1 carefully curated recommendation for each time slot
      2. Use REAL, SPECIFIC place names (not generic descriptions)
      3. Include EXACT official names (e.g., "Café Central Wien" not just "a café")
      4. Output ONLY HTML (no markdown, no code blocks, no extra text)
      5. Each recommendation MUST be in a div with class="recommendation"

      **HTML STRUCTURE - FOLLOW EXACTLY:**

      <div class="itinerary">
        <p class="intro">Write a compelling 2-sentence intro about the day's theme and what makes this itinerary special for #{city.name}#{city.date.present? ? " in #{(city.date.is_a?(String) ? Date.parse(city.date) : city.date).strftime('%B %Y')}" : ""}.</p>

        <div class="time-slot">
          <h2>☀️ Morning: 9:00 AM - 11:00 AM | Activity Type</h2>

          <div class="recommendation" data-place-name="EXACT PLACE NAME HERE">
            <img src="placeholder" alt="EXACT PLACE NAME" class="place-image" style="display:none;">
            <h3>EXACT PLACE NAME (Official Name)</h3>
            <p class="address">Full street address, #{city.name}</p>
            <p class="description">2-3 sentences explaining why this is perfect. Be specific about what makes this place special#{city.date.present? ? " and why it's great to visit in #{(city.date.is_a?(String) ? Date.parse(city.date) : city.date).strftime('%B')}" : ""}.</p>
            <p class="details"><em>Best for: #{filters_text} | Duration: X hours | Price: €/€€/€€€</em></p>
          </div>
        </div>

        <div class="time-slot">
          <h2>☀️ Midday: 11:30 AM - 1:30 PM | Lunch</h2>

          <div class="recommendation" data-place-name="EXACT RESTAURANT NAME HERE">
            <img src="placeholder" alt="EXACT RESTAURANT NAME" class="place-image" style="display:none;">
            <h3>EXACT RESTAURANT NAME</h3>
            <p class="address">Full street address, #{city.name}</p>
            <p class="description">Why this restaurant is perfect. Mention signature dishes or unique atmosphere#{city.date.present? ? ". Note any seasonal menu items available in #{(city.date.is_a?(String) ? Date.parse(city.date) : city.date).strftime('%B')}" : ""}.</p>
            <p class="details"><em>Cuisine: type | Signature dish: dish name | Price: €/€€/€€€</em></p>
          </div>
        </div>

        <div class="time-slot">
          <h2>🌤️ Afternoon: 2:00 PM - 5:00 PM | Activity Type</h2>

          <div class="recommendation" data-place-name="EXACT PLACE NAME HERE">
            <img src="placeholder" alt="EXACT PLACE NAME" class="place-image" style="display:none;">
            <h3>EXACT PLACE NAME</h3>
            <p class="address">Full street address, #{city.name}</p>
            <p class="description">Description with specific details about what to see or do here.</p>
            <p class="details"><em>Best for: #{filters_text} | Duration: X hours | Price: €/€€/€€€</em></p>
          </div>
        </div>

        <div class="time-slot">
          <h2>🌆 Evening: 6:00 PM - 9:00 PM | Dinner/Activity</h2>

          <div class="recommendation" data-place-name="EXACT PLACE NAME HERE">
            <img src="placeholder" alt="EXACT PLACE NAME" class="place-image" style="display:none;">
            <h3>EXACT PLACE NAME</h3>
            <p class="address">Full street address, #{city.name}</p>
            <p class="description">Why this is the perfect end to the day.</p>
            <p class="details"><em>Best for: #{filters_text} | Price: €/€€/€€€</em></p>
          </div>
        </div>

        <div class="pro-tips">
          <h2>💡 Pro Tips for #{city.name}</h2>
          <ul>
            <li><strong>Transportation:</strong> Practical tip about getting around #{city.name}</li>
            <li><strong>Local Insider:</strong> A hidden gem or local secret most tourists miss</li>
            <li><strong>Money Saver:</strong> Cost-saving tip specific to #{city.name}</li>
            #{if city.date.present?
              trip_date = city.date.is_a?(String) ? Date.parse(city.date) : city.date
              "<li><strong>Festival/Event:</strong> Research and mention a specific festival, event, market, or cultural happening in #{city.name} during #{trip_date.strftime('%B %Y')}. If it relates to the user's interests (#{filters_text}), explain why they shouldn't miss it. Include exact dates if known. If no major events, mention seasonal activities unique to #{city.name} during this time of year.</li>"
            else
              "<li><strong>Cultural Events:</strong> Mention popular annual festivals or events in #{city.name} that align with these interests: #{filters_text}. Include typical months when they occur.</li>"
            end}
          </ul>
        </div>
      </div>

      **CRITICAL REQUIREMENTS FOR FESTIVALS/EVENTS:**
      - Research REAL festivals and events specific to #{city.name}
      - If a trip date is provided, find events happening during that specific month/season
      - Prioritize events that match user interests: #{filters_text}
      - Include event names, typical dates, and why it's relevant to the user
      - Examples: music festivals, food markets, art exhibitions, cultural celebrations
      - If unsure about specific dates, mention "typically held in [month]"

      **GENERAL REQUIREMENTS:**
      - All places MUST be real, currently operating locations in #{city.name}
      - Use exact official names as they appear on Google Maps
      - Include full street addresses
      - The data-place-name attribute MUST contain the exact searchable name
      - Each recommendation MUST use: <div class="recommendation" data-place-name="...">
      - NO generic descriptions like "a popular café" - give the actual name
      - Keep descriptions under 50 words
      - Match recommendations to these interests: #{filters_text}
      #{if city.date.present?
        trip_date = city.date.is_a?(String) ? Date.parse(city.date) : city.date
        "- Consider seasonal weather and conditions for #{trip_date.strftime('%B')} in #{city.name}"
      end}

      **EXAMPLE OF GOOD vs BAD:**
      ❌ BAD: <div class="recommendation" data-place-name="museum">
      ✅ GOOD: <div class="recommendation" data-place-name="Rijksmuseum">

      ❌ BAD: <h3>A cozy café in the center</h3>
      ✅ GOOD: <h3>Café Central Wien</h3>

      ❌ BAD: <div class="place-recommendation"> (wrong class name)
      ✅ GOOD: <div class="recommendation"> (correct class name)

      ❌ BAD Festival Tip: "There might be some events happening"
      ✅ GOOD Festival Tip: "The Vienna Jazz Festival (June 25-July 15) features international artists at venues across the city - perfect for music lovers! Book tickets in advance."
    PROMPT
  end

  def enhance_with_google_photos(ai_response, city)
    return ai_response if ai_response.blank?

    Rails.logger.info "🎨 Starting photo enhancement for #{city.name}"

    photo_service = GooglePlacesPhotoService.new
    doc = Nokogiri::HTML.fragment(ai_response)

    # Find all recommendations
    recommendations = doc.css('.recommendation')
    Rails.logger.info "📋 Found #{recommendations.count} recommendations"

    recommendations.each_with_index do |recommendation, index|
      # Get place name from data attribute (most reliable)
      place_name = recommendation['data-place-name']

      # Fallback to h3 if data attribute is missing
      place_name ||= recommendation.at_css('h3')&.text&.strip

      next unless place_name.present?

      Rails.logger.info "🔍 Fetching photo for: #{place_name} in #{city.name}"

      # Get photo from Google Places
      photo_url = photo_service.get_place_photo(place_name, city.name)

      if photo_url
        Rails.logger.info "✅ Photo URL received: #{photo_url[0..80]}..."

        img_tag = recommendation.at_css('img.place-image')

        if img_tag
          # Update existing img tag
          img_tag['src'] = photo_url
          img_tag.remove_attribute('style') # Remove display:none
          img_tag['onerror'] = "this.style.display='none'"
          img_tag['loading'] = 'lazy'
          Rails.logger.info "✅ Updated existing img tag"
        else
          # Create new img tag - Fixed version that works with fragments
          h3_tag = recommendation.at_css('h3')
          if h3_tag
            # Build img tag as HTML string and parse it
            img_html = %Q(<img src="#{photo_url}" alt="#{place_name}" class="place-image" loading="lazy" onerror="this.style.display='none'">)
            img_node = Nokogiri::HTML.fragment(img_html).children.first
            h3_tag.add_previous_sibling(img_node)
            Rails.logger.info "✅ Created and inserted new img tag"
          end
        end

        # Add photo credit if not exists
        unless recommendation.at_css('.photo-credit')
          credit_html = '<p class="photo-credit">Photo: Google Maps</p>'
          credit_node = Nokogiri::HTML.fragment(credit_html).children.first
          img_tag = recommendation.at_css('img.place-image')
          img_tag.add_next_sibling(credit_node) if img_tag
          Rails.logger.info "✅ Photo credit added"
        end
      else
        Rails.logger.warn "❌ No photo found for #{place_name}"

        # Hide placeholder if it exists
        img_tag = recommendation.at_css('img.place-image')
        img_tag['style'] = 'display:none' if img_tag
      end
    end

    Rails.logger.info "✅ Photo enhancement complete"
    doc.to_html
  rescue StandardError => e
    Rails.logger.error "❌ Error enhancing with Google photos: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    ai_response
  end

  def message_params
    params.require(:message).permit(:content)
  end

  def build_conversation_history
    @chat.messages.select {|m| m.content != "" }.each do |message|
      @ruby_llm_chat.add_message(message)
    end
  end
end
