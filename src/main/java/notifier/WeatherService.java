package notifier;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;

public class WeatherService {
    private static final String API_KEY = System.getenv("OPENWEATHER_API_KEY");
    private static final String API_URL = "https://api.openweathermap.org/data/2.5/weather";
    
    public static String getForecast(String city) {
        try {
            String url = String.format("%s?q=%s&appid=%s&units=metric", API_URL, city, API_KEY);
            
            CloseableHttpClient httpClient = HttpClients.createDefault();
            HttpGet request = new HttpGet(url);
            CloseableHttpResponse response = httpClient.execute(request);
            
            String json = EntityUtils.toString(response.getEntity());
            ObjectMapper mapper = new ObjectMapper();
            JsonNode root = mapper.readTree(json);
            
            String weather = root.path("weather").get(0).path("main").asText();
            double temp = root.path("main").path("temp").asDouble();
            
            return String.format("%s, %.1f°C", weather, temp);
        } catch (Exception e) {
            return "Unable to fetch weather data";
        }
    }
}
