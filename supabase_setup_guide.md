# Supabase Database Setup Guide

## Overview
This guide will help you set up the Supabase database for your Agricultural Climate App with all the necessary tables, functions, and data.

## Files Included
1. `supabase_schema_fixed.sql` - Main database schema (use this one)
2. `supabase_functions.sql` - Additional utility functions
3. `supabase_schema.sql` - Original schema (has some issues with partial indexes)

## Setup Steps

### 1. Create Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Create a new project
3. Note down your project URL and API keys

### 2. Run the Database Schema
1. Open the Supabase SQL Editor
2. Copy and paste the contents of `supabase_schema_fixed.sql`
3. Execute the script
4. Verify all tables are created successfully

### 3. Add Utility Functions (Optional)
1. Copy and paste the contents of `supabase_functions.sql`
2. Execute the script
3. These functions provide additional query capabilities

### 4. Configure Environment Variables
Add these to your Flutter app's environment:

```dart
// In your .env file or environment configuration
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 5. Update Flutter Dependencies
Make sure you have the required dependencies in your `pubspec.yaml`:

```yaml
dependencies:
  supabase_flutter: ^2.0.0
  http: ^1.1.0
```

## Database Schema Overview

### Core Tables
- **weather_data** - Main weather information with enhanced fields
- **air_quality_data** - Air quality metrics for agricultural monitoring
- **pollen_data** - Pollen information for agricultural planning
- **astronomy_data** - Sunrise/sunset and moon data for timing
- **weather_alerts** - Weather warnings and alerts
- **soil_data** - Soil conditions and measurements
- **agricultural_recommendations** - AI-generated farming advice
- **agro_climatic_predictions** - Weather and crop predictions
- **user_preferences** - User settings and location preferences
- **notifications** - User notifications and alerts

### Key Features
- **Enhanced Weather Data**: Includes UV index, feels-like temperature, dew point, wind gust, cloud cover
- **Air Quality Monitoring**: PM2.5, PM10, O3, NO2, SO2, CO levels with EPA and DEFRA indices
- **Pollen Data**: Hazel, Alder, Birch, Oak, Grass, Mugwort, Ragweed pollen levels
- **Astronomy Data**: Sunrise/sunset times, moon phases, and illumination
- **Agricultural Focus**: Soil data, crop recommendations, and climate predictions
- **Zimbabwe Locations**: Pre-configured with major Zimbabwe cities

### Indexes and Performance
- Comprehensive indexing for fast queries
- Optimized for location-based and time-based queries
- No problematic partial indexes that cause IMMUTABLE function errors

### Row Level Security (RLS)
- Public read access for weather and agricultural data
- User-specific access for preferences and notifications
- Secure data access patterns

## Usage Examples

### Get Current Weather
```sql
SELECT * FROM get_current_weather('Harare');
```

### Get Air Quality
```sql
SELECT * FROM get_current_air_quality('Harare');
```

### Get Pollen Data
```sql
SELECT * FROM get_current_pollen_data('Harare');
```

### Get Agricultural Recommendations
```sql
SELECT * FROM get_agricultural_recommendations('Harare', 'maize');
```

### Get Weather Statistics
```sql
SELECT * FROM get_weather_statistics('Harare', '2024-01-01', '2024-01-31');
```

## Troubleshooting

### Common Issues
1. **IMMUTABLE Function Error**: Use `supabase_schema_fixed.sql` instead of the original
2. **Permission Errors**: Ensure RLS policies are properly set up
3. **Missing Data**: Check if sample data was inserted correctly

### Verification Queries
```sql
-- Check if tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check sample data
SELECT COUNT(*) FROM user_preferences;
SELECT COUNT(*) FROM weather_data;

-- Test functions
SELECT get_pollen_risk_level(50.0);
SELECT calculate_air_quality_index(25.0, 30.0, 100.0, 50.0, 20.0, 2.0);
```

## Next Steps
1. Test the database connection from your Flutter app
2. Implement data synchronization with WeatherAPI.com
3. Set up automated data collection
4. Configure push notifications for weather alerts
5. Implement user preference management

## Support
If you encounter any issues:
1. Check the Supabase logs in the dashboard
2. Verify your API keys and project configuration
3. Ensure all SQL scripts executed without errors
4. Test individual functions and queries

The database is now ready to support your Agricultural Climate App with comprehensive weather, agricultural, and user data management capabilities!

