class MessagesController < ApplicationController

def create
  # raise

  @chat = current_user.chats.find(params[:chat_id])
  @city = @chat.city

  @message = Message.new(message_params)
  @message.chat = @chat
  @message.role = "user"

    if @message.save

      system_prompt = build_system_prompt(@city)
      ruby_llm_chat = RubyLLM.chat

      user_input = if @message.content.present?
                    "Additional things to consider: #{@message.content}"
                  else
                    "No additional considerations"
                  end
      response = ruby_llm_chat.with_instructions(system_prompt).ask(user_input)

      Message.create!(role: "assistant", content: response.content, chat: @chat)
      @city.update(itinerary: response.content)
      redirect_to chat_path(@chat)
    else
      render "chats/show", status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
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

    **CRITICAL: Provide exactly 3 options for each time slot**

    **OUTPUT FORMAT - USE HTML:**

    <div class="itinerary">
      <p class="intro">Start with a 2-sentence intro about the day's theme</p>

      <div class="time-slot">
        <h2>☀️ Morning: 9:00 AM - 11:00 AM | Activity Type</h2>

        <div class="option">
          <h3>Option 1: Place Name</h3>
          <p>Description (1-2 sentences)</p>
          <p class="details"><em>Best for: audience | Price: €/€€/€€€</em></p>
        </div>

        <div class="option">
          <h3>Option 2: Place Name</h3>
          <p>Description</p>
          <p class="details"><em>Best for: audience | Price: €/€€/€€€</em></p>
        </div>

        <div class="option">
          <h3>Option 3: Place Name</h3>
          <p>Description</p>
          <p class="details"><em>Best for: audience | Price: €/€€/€€€</em></p>
        </div>
      </div>

      <!-- Repeat for Afternoon and Evening -->

      <div class="pro-tips">
        <h2>💡 Pro Tips</h2>
        <ul>
          <li>Tip 1</li>
          <li>Tip 2</li>
          <li>Tip 3</li>
        </ul>
      </div>
    </div>

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
