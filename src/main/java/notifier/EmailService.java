package notifier;

import javax.mail.*;
import javax.mail.internet.*;
import java.util.Properties;

public class EmailService {
    private static final String FROM_EMAIL = System.getenv("FROM_EMAIL");
    private static final String SMTP_PASSWORD = System.getenv("SMTP_PASSWORD");
    
    public static void sendEmail(String to, String content) {
        try {
            // Free Gmail SMTP configuration
            Properties props = new Properties();
            props.put("mail.smtp.auth", "true");
            props.put("mail.smtp.starttls.enable", "true");
            props.put("mail.smtp.host", "smtp.gmail.com");
            props.put("mail.smtp.port", "587");
            
            Session session = Session.getInstance(props, new Authenticator() {
                @Override
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication(FROM_EMAIL, SMTP_PASSWORD);
                }
            });
            
            Message message = new MimeMessage(session);
            message.setFrom(new InternetAddress(FROM_EMAIL));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to));
            message.setSubject("🌤️ Weather Notification");
            message.setContent(content, "text/html; charset=utf-8");
            
            Transport.send(message);
        } catch (Exception e) {
            System.err.println("Failed to send email: " + e.getMessage());
            // Don't throw exception in free version - just log
        }
    }

    public static String buildEmail(String city, String forecast, String suggestion) {
        return buildEmail(city, forecast, suggestion, null);
    }
    
    public static String buildEmail(String city, String forecast, String suggestion, String detectedIP) {
        String locationInfo = "";
        if (detectedIP != null && !detectedIP.equals("unknown") && !detectedIP.equals("127.0.0.1")) {
            locationInfo = "<p><small><em>📍 Location auto-detected from your IP: " + detectedIP + "</em></small></p>";
        }
        
        return "<html><body style='font-family: Arial, sans-serif; margin: 20px;'>" +
               "<div style='max-width: 600px; margin: 0 auto; border: 1px solid #ddd; border-radius: 10px; padding: 20px;'>" +
               "<h2 style='color: #4CAF50; text-align: center;'>🌤️ Weather Update</h2>" +
               "<h3 style='color: #333;'>📍 " + city + "</h3>" +
               "<div style='background: #f9f9f9; padding: 15px; border-radius: 5px; margin: 10px 0;'>" +
               "<p><strong>🌡️ Current Weather:</strong> " + forecast + "</p>" +
               "<p><strong>💡 Suggestion:</strong> " + suggestion + "</p>" +
               "</div>" +
               locationInfo +
               "<hr style='margin: 20px 0; border: none; height: 1px; background: #ddd;'>" +
               "<p style='text-align: center; color: #666;'>" +
               "<small>🆓 Powered by your FREE Weather Notifier | " +
               "Data from OpenWeatherMap | Sent via Gmail SMTP</small>" +
               "</p>" +
               "<p style='text-align: center; margin-top: 20px;'>Have a great day! ☀️</p>" +
               "</div></body></html>";
    }
}
