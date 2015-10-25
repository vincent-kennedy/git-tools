package viking.atlassian.tools.util;

import org.apache.commons.codec.binary.Base64;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import java.io.Console;
import java.security.Key;
import java.util.Arrays;

/**
 * Handles API auth details.
 *
 * @author Andreas Borglin
 */
public class ApiAuthUtil {

    private static final String ENC_ALGO = "AES";
    private static final byte[] ENC_KEY = {'1', 'n', '3', 'g', '4', 'm', 'g', '9', 'h', '2', 'b', '5', 'q', 'z', '5', 'j'};
    private static final String ENC_FILE = ".atlapikey";
    private static final String USER_NAME_FILE = ".atlassianusername";

    private static String encrypt(String input) throws Exception {
        Key key = new SecretKeySpec(ENC_KEY, ENC_ALGO);
        Cipher c = Cipher.getInstance(ENC_ALGO);
        c.init(Cipher.ENCRYPT_MODE, key);
        byte[] encVal = c.doFinal(input.getBytes());
        String encryptedValue = Base64.encodeBase64String(encVal);
        return encryptedValue;
    }

    private static String decrypt(String input) throws Exception {
        Key key = new SecretKeySpec(ENC_KEY, ENC_ALGO);
        Cipher c = Cipher.getInstance(ENC_ALGO);
        c.init(Cipher.DECRYPT_MODE, key);
        byte[] decordedValue = Base64.decodeBase64(input.getBytes());
        byte[] decValue = c.doFinal(decordedValue);
        return new String(decValue);
    }

    private static final String getFilePath(String file) {
        if (System.getProperty("os.name").startsWith("Windows")) {
            return System.getProperty("user.home") + "\\" + file;
        }
        else {
            return System.getProperty("user.home") + "/" + file;
        }
    }

    public static String encryptUserDetails() {

        Console console = System.console();
        System.out.println();
        String userName = console.readLine("Enter your JIRA/Stash user name: ");
        String passwordStr = null;
        while (true) {
            char[] password = console.readPassword("Enter your JIRA/Stash password: ");
            char[] passwordRepeat = console.readPassword("Please confirm your JIRA/Stash password: ");
            if (!Arrays.equals(password, passwordRepeat)) {
                System.out.println("Passwords don't match!");
                continue;
            }
            passwordStr = new String(password);
            break;
        }

        String httpAuth = userName + ":" + passwordStr;
        String base64encoded = Base64.encodeBase64String(httpAuth.getBytes());

        try {
            String encoded = encrypt(base64encoded);
            FileUtil.writeStringToFile(getFilePath(ENC_FILE), encoded);

        }
        catch (Exception e) {
            System.out.println("Failed to encrypt user details.");
            e.printStackTrace();
        }

        return base64encoded;
    }

    public static String getUserAuthDetails() {
        try {
            String encrypted = FileUtil.readStringFromFile(getFilePath(ENC_FILE));
            String decrypted = decrypt(encrypted);
            return decrypted;
        }
        catch (Exception e) {
            // Ignore
        }
        return null;
    }

    public static String saveUserName() {
        Console console = System.console();
        System.out.println();
        String userName = console.readLine("Enter your JIRA/Stash user name: ").trim();
        if (userName != null && userName.length() > 0) {
            FileUtil.writeStringToFile(getFilePath(USER_NAME_FILE), userName);
        }
        return userName;
    }

    public static String getUserName() {
        try {
            String userName = FileUtil.readStringFromFile(getFilePath(USER_NAME_FILE)).trim();
            return userName;
        }
        catch (Exception e) {
            // Ignore
        }
        return null;
    }

    public static String getUserNameFromAuthString(String authString) {
        String unbased = new String(Base64.decodeBase64(authString));
        return unbased.substring(0, unbased.indexOf(':'));
    }

    public static String getApiAuthFromUserName(String userName) {
        Console console = System.console();
        System.out.println();
        char[] password = console.readPassword("Enter your JIRA/Stash password: ");
        String passwordStr = new String(password);
        if (passwordStr != null && passwordStr.length() > 0) {
            String authString = userName + ":" + passwordStr.trim();
            return Base64.encodeBase64String(authString.getBytes());
        }
        return null;
    }

}
