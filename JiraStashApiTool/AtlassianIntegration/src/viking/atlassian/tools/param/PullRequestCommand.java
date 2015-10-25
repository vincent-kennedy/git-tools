package viking.atlassian.tools.param;

import com.beust.jcommander.Parameters;
import com.beust.jcommander.Parameter;

/**
 * Pull request command for JCommander cmdline parsing.
 * @author Andreas Borglin
 */
@Parameters(commandDescription = "Pull requests", separators = "=")
public class PullRequestCommand {

    public static final String TAG = "pullRequest";

    @Parameter(names = "--repo")
    private String repo;

    @Parameter(names = "--srcBranch")
    private String sourceBranch;

    @Parameter(names = "--destBranch")
    private String destBranch;

    @Parameter(names = "--commitTitle")
    private String commitTitle;

    @Parameter(names = "--fromUserRepo", arity = 1)
    private boolean isFromUserRepo = true;

    @Parameter(names = "--debug", arity = 1)
    private boolean debug = false;

    public String getRepo() {
        return repo;
    }

    public String getSourceBranch() {
        return sourceBranch;
    }

    public String getDestBranch() {
        return destBranch;
    }

    public String getCommitTitle() {
        return commitTitle;
    }

    public boolean isFromUserRepo() {
        return isFromUserRepo;
    }

    public boolean isDebug() {
        return debug;
    }
}
