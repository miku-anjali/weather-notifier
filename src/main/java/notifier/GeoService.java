package notifier;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;

public class GeoService {
    public static String detectCity(String ip) {
        try {
            if (ip == null || ip.isEmpty() || ip.equals("127.0.0.1") || ip.equals("localhost")) {
                return "Mumbai"; // Default Indian city for local testing
            }
            
            // Try multiple FREE geolocation services for better accuracy
            String city = tryIPAPIService(ip);
            if (city == null || city.isEmpty()) {
                city = tryFreeGeoIPService(ip);
            }
            
            return (city != null && !city.isEmpty()) ? city : "Mumbai";
        } catch (Exception e) {
            System.err.println("GeoService error: " + e.getMessage());
            return "Mumbai"; // Indian default fallback
        }
    }
    
    // Primary FREE geolocation service
    private static String tryIPAPIService(String ip) {
        try {
            String url = String.format("https://ipapi.co/%s/json/", ip);
            
            CloseableHttpClient httpClient = HttpClients.createDefault();
            HttpGet request = new HttpGet(url);
            request.addHeader("User-Agent", "WeatherNotifier/1.0");
            CloseableHttpResponse response = httpClient.execute(request);
            
            String json = EntityUtils.toString(response.getEntity());
            ObjectMapper mapper = new ObjectMapper();
            JsonNode root = mapper.readTree(json);
            
            String city = root.path("city").asText();
            String country = root.path("country_name").asText();
            
            // For better weather accuracy, use larger cities for some countries
            if ("India".equals(country)) {
                // Check if it's a major Indian city, otherwise use regional capital
                if (city != null && !city.isEmpty()) {
                    return city;
                }
            }
            
            return city;
        } catch (Exception e) {
            return null;
        }
    }
    
    // Backup FREE geolocation service
    private static String tryFreeGeoIPService(String ip) {
        try {
            String url = String.format("http://ip-api.com/json/%s", ip);
            
            CloseableHttpClient httpClient = HttpClients.createDefault();
            HttpGet request = new HttpGet(url);
            request.addHeader("User-Agent", "WeatherNotifier/1.0");
            CloseableHttpResponse response = httpClient.execute(request);
            
            String json = EntityUtils.toString(response.getEntity());
            ObjectMapper mapper = new ObjectMapper();
            JsonNode root = mapper.readTree(json);
            
            if ("success".equals(root.path("status").asText())) {
                return root.path("city").asText();
            }
            
            return null;
        } catch (Exception e) {
            return null;
        }
    }
}
