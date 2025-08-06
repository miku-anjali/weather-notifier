package notifier;

import org.junit.Test;
import static org.junit.Assert.*;

public class SuggestionEngineTest {
    
    @Test
    public void testRainSuggestion() {
        String suggestion = SuggestionEngine.getSuggestion("Rain");
        assertEquals("Carry an umbrella.", suggestion);
    }
    
    @Test
    public void testSnowSuggestion() {
        String suggestion = SuggestionEngine.getSuggestion("Snow");
        assertEquals("Wear warm clothes.", suggestion);
    }
    
    @Test
    public void testDefaultSuggestion() {
        String suggestion = SuggestionEngine.getSuggestion("Sunny");
        assertEquals("Have a great day!", suggestion);
    }
    
    @Test
    public void testCaseInsensitive() {
        String suggestion = SuggestionEngine.getSuggestion("RAIN");
        assertEquals("Carry an umbrella.", suggestion);
    }
}
