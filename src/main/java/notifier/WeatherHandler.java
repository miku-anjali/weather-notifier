package notifier;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import java.util.Map;

public class WeatherHandler implements RequestHandler<Map<String, Object>, String> {
    public String handleRequest(Map<String, Object> event, Context context) {
        String email = (String) event.get("email");
        String city = (String) event.get("city");

        if (city == null || city.isEmpty()) {
            city = GeoService.detectCity((String) event.get("ip"));
        }

        String forecast = WeatherService.getForecast(city);
        String suggestion = SuggestionEngine.getSuggestion(forecast);
        String content = EmailService.buildEmail(city, forecast, suggestion);

        EmailService.sendEmail(email, content);
        return "Notification sent.";
    }
}
