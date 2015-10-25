package viking.atlassian.tools.param;

import com.beust.jcommander.Parameter;
import com.beust.jcommander.Parameters;

/**
 * @author Andreas Borglin
 */
@Parameters(commandDescription = "Auth details", separators = "=")
public class AuthDetailsCommand {

    public static final String TAG = "authDetails";

    @Parameter(names = "--persistDetails")
    private boolean persistDetails = false;

    @Parameter(names = "--persistUserName")
    private boolean persistUserName = false;

    public boolean isPersistDetails() {
        return persistDetails;
    }

    public boolean isPersistUserName() {
        return persistUserName;
    }
}
