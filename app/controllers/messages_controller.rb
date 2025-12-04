class MessagesController < ApplicationController
def create

  @chat = current_user.chats.find(params[:chat_id])
  @city = @chat.city

  @message = Message.new(message_params)
  @message.chat = @chat
  @message.role = "user"
  @chat.generate_title_from_first_message # NEW

    if @message.save

      system_prompt = build_system_prompt(@city)
      @ruby_llm_chat = RubyLLM.chat
      build_conversation_history
      if @message.content.present?
        user_input = "Additional things to consider: #{@message.content}"
      else
        user_input = "No additional considerations"
      end
      response = @ruby_llm_chat.with_instructions(system_prompt).ask(user_input)
      Message.create!(role: "assistant", content: response.content, chat: @chat)
      @city.update(itinerary: response.content)
      @chat.generate_title_from_first_message
      redirect_to chat_path(@chat)
    else
      render "chats/show", status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end

  def build_conversation_history
    @chat.messages.select {|m| m.content != "" }.each do |message|
    @ruby_llm_chat.add_message(message)
    end
  end

  def build_system_prompt(city)
    # Handle filters as array
    if city.filters.present? && city.filters.any?
      filters_text = city.filters.reject(&:blank?).join(", ")
      # interest_section = "USER INTERESTS: #{filters_text}"
    else
      filters_text = "#{city.name}'s general and most popular highlights."
    end

<<~PROMPT
    You are a Local Travel Expert specializing in #{city.name}.

    USER PROFILE:
    - Destination: #{city.name}
    - Interests: #{filters_text}

    TASK:
    Create a personalized day trip itinerary for #{city.name} that matches these specific interests: #{filters_text}

    **CRITICAL: Provide exactly 1 carefully curated recommendation for each time slot - your absolute best suggestion that perfectly matches their interests**

    **OUTPUT FORMAT - USE HTML:**

    <div class="itinerary">
      <p class="intro">Start with a 2-sentence intro about the day's theme</p>

      <div class="time-slot">
        <h2>☀️ Morning: 9:00 AM - 11:00 AM | Activity Type</h2>

        <div class="recommendation">
          <img src="https://images.unsplash.com/photo-1506748686214-e9df14d4d9d0?w=800&h=400&fit=crop" alt="Place Name" class="place-image" onerror="this.style.display='none'">
          <h3>Place Name</h3>
          <p>Description (2-3 sentences explaining why this is the perfect choice)</p>
          <p class="details"><em>Best for: audience | Duration: X hours | Price: €/€€/€€€</em></p>
        </div>
      </div>

      <div class="time-slot">
        <h2>☀️ Midday: 11:30 AM - 1:30 PM | Lunch</h2>

        <div class="recommendation">
          <img src="https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800&h=400&fit=crop" alt="Restaurant Name" class="place-image" onerror="this.style.display='none'">
          <h3>Restaurant/Café Name</h3>
          <p>Description</p>
          <p class="details"><em>Cuisine: type | Price: €/€€/€€€</em></p>
        </div>
      </div>

      <div class="time-slot">
        <h2>🌤️ Afternoon: 2:00 PM - 5:00 PM | Activity Type</h2>

        <div class="recommendation">
          <img src="https://images.unsplash.com/photo-1506748686214-e9df14d4d9d0?w=800&h=400&fit=crop" alt="Place Name" class="place-image" onerror="this.style.display='none'">
          <h3>Place Name</h3>
          <p>Description</p>
          <p class="details"><em>Best for: audience | Duration: X hours | Price: €/€€/€€€</em></p>
        </div>
      </div>

      <div class="time-slot">
        <h2>🌆 Evening: 6:00 PM - 9:00 PM | Activity Type</h2>

        <div class="recommendation">
          <img src="https://images.unsplash.com/photo-1506748686214-e9df14d4d9d0?w=800&h=400&fit=crop" alt="Place Name" class="place-image" onerror="this.style.display='none'">
          <h3>Place Name</h3>
          <p>Description</p>
          <p class="details"><em>Best for: audience | Price: €/€€/€€€</em></p>
        </div>
      </div>

      <div class="pro-tips">
        <h2>💡 Pro Tips</h2>
        <ul>
          <li>Tip 1</li>
          <li>Tip 2</li>
          <li>Tip 3</li>
        </ul>
      </div>
    </div>

    IMAGE REQUIREMENTS:
    - For each recommendation, use relevant Unsplash image URLs
    - Format: https://images.unsplash.com/photo-XXXXXXXXX?w=800&h=400&fit=crop
    - Search for actual Unsplash photos related to #{city.name} landmarks/venues
    - Include onerror="this.style.display='none'" as fallback
    - Use descriptive alt text for each image
    REQUIREMENTS:
    - Output ONLY HTML (no markdown)
    - All places must be REAL locations in #{city.name}
    - Prioritize these interests: #{filters_text}
    - Include diverse price points
    - Use the exact HTML structure shown above
    - Keep descriptions under 25 words
    - Ask which options they want
  PROMPT
  end
end
