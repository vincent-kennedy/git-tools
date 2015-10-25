package viking.atlassian.tools.util;

import java.io.IOException;
import java.io.PrintWriter;
import java.nio.ByteBuffer;
import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.Paths;

/**
 * File utils.
 *
 * @author Andreas Borglin
 */
public class FileUtil {

    public static boolean writeStringToFile(String path, String content) {
        PrintWriter writer = null;
        try {
            writer = new PrintWriter(path);
            writer.println(content);
            writer.flush();
            return true;
        }
        catch (Exception e) {
            e.printStackTrace();
            return false;
        }
        finally {
            if (writer != null) {
                writer.close();
            }
        }
    }

    public static String readStringFromFile(String path) throws IOException {
        byte[] encoded = Files.readAllBytes(Paths.get(path));
        Charset charset = Charset.defaultCharset();
        String content = charset.decode(ByteBuffer.wrap(encoded)).toString();
        return content;
    }
}
