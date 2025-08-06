package notifier;

public class SuggestionEngine {
    public static String getSuggestion(String forecast) {
        switch (forecast.toLowerCase()) {
            case "rain":
                return "Carry an umbrella.";
            case "snow":
                return "Wear warm clothes.";
            default:
                return "Have a great day!";
        }
    }
}
