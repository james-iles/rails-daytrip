# DayTrip

An AI-powered day trip planner that creates personalized one-day city itineraries based on your interests.

## What it does

Tell DayTrip where you want to go, pick your interests (coffee spots, museums, hiking, nightlife, etc.), and get a custom itinerary with place recommendations and photos. You can have multiple conversations to refine your plans and save notes for each trip.

## Features

- AI-generated itineraries tailored to your selected interests
- Real photos from Google Places for each recommendation
- Multi-turn chat to refine and explore your plans
- Notes section to save your own thoughts on each trip
- User accounts to keep track of all your planned adventures

## Tech Stack

- **Backend:** Ruby on Rails 7.1, Ruby 3.3.5
- **Database:** PostgreSQL
- **AI:** RubyLLM (OpenAI)
- **Photos:** Google Places API
- **Frontend:** Bootstrap 5, Turbo, Stimulus
- **Auth:** Devise

## Setup

```bash
# Install dependencies
bundle install

# Setup database
rails db:create db:migrate

# Add your API keys to .env
OPENAI_API_KEY=your_key
GOOGLE_PLACES_API_KEY=your_key

# Start the server
rails server
```

## Team

Built by **Ferizzat Jussupbekova**, **Joao Dias**, and **James Iles**.

Product Manager: James Iles

## Deployment

This app is deployed on Render using a PostgreSQL database.
Secrets are managed via environment variables.

---

Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates), created by the [Le Wagon coding bootcamp](https://www.lewagon.com) team.
