package viking.atlassian.tools;

import com.beust.jcommander.JCommander;
import viking.atlassian.tools.api.ApiHelper;
import viking.atlassian.tools.api.JiraService;
import viking.atlassian.tools.api.StashService;
import viking.atlassian.tools.api.model.JiraTransition;
import viking.atlassian.tools.api.model.JiraTransitionsResponse;
import viking.atlassian.tools.api.model.PullRequest;
import viking.atlassian.tools.api.model.PullRequestResponse;
import viking.atlassian.tools.param.AuthDetailsCommand;
import viking.atlassian.tools.param.PullRequestCommand;
import viking.atlassian.tools.param.TransitionIssueCommand;
import viking.atlassian.tools.util.ApiAuthUtil;
import viking.atlassian.tools.util.GitUtil;
import viking.atlassian.tools.util.ReviewersHelper;
import org.apache.http.client.HttpClient;
import org.apache.http.conn.ssl.SSLConnectionSocketFactory;
import org.apache.http.conn.ssl.SSLContextBuilder;
import org.apache.http.conn.ssl.TrustSelfSignedStrategy;
import org.apache.http.conn.ssl.TrustStrategy;
import org.apache.http.impl.client.HttpClients;
import retrofit.RestAdapter;
import retrofit.client.ApacheClient;

import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/**
 * Main class - entry point.
 *
 * @author Andreas Borglin
 */
public class Main {

    public static void main(String[] args) {

        try {

            JCommander jc = new JCommander();
            PullRequestCommand prCom = new PullRequestCommand();
            AuthDetailsCommand authCom = new AuthDetailsCommand();
            TransitionIssueCommand trCom = new TransitionIssueCommand();
            jc.addCommand(PullRequestCommand.TAG, prCom);
            jc.addCommand(AuthDetailsCommand.TAG, authCom);
            jc.addCommand(TransitionIssueCommand.TAG, trCom);

            jc.parse(args);

            if (jc.getParsedCommand().equals(PullRequestCommand.TAG)) {
                handlePullRequest(prCom.getRepo(), prCom.getSourceBranch(), prCom.getDestBranch(),
                        prCom.getCommitTitle(),
                        prCom.isFromUserRepo(), prCom.isDebug());
            }
            else if (jc.getParsedCommand().equals(AuthDetailsCommand.TAG)) {
                if (authCom.isPersistDetails()) {
                    ApiAuthUtil.encryptUserDetails();
                }
                else if (authCom.isPersistUserName()) {
                    ApiAuthUtil.saveUserName();
                }
                else {
                    System.out.println("Need to specify either: --persistDetails or --persistUserName");
                }
            }
            else if (jc.getParsedCommand().equals(TransitionIssueCommand.TAG)) {
                handleJiraIssueTransition(trCom.getTopicBranch(), trCom.getDestBranch(), trCom.getTransition(),
                        trCom.getBaseCommit(), trCom.isDebug());
            }
            else {
                System.out.println("Unknown command: " + jc.getParsedCommand());
            }

        }
        catch (Exception e) {
            e.printStackTrace();
            System.exit(1);
        }
    }

    private static void handlePullRequest(String repo, String srcBranch, String destBranch, String commitTitle,
                                          boolean fromUserRepo, boolean debug) {

        if (debug) {
            System.out.println("Creating pull request with, ");
            System.out.println("Repository: " + repo);
            System.out.println("Source branch: " + srcBranch);
            System.out.println("Destination branch: " + destBranch);
            System.out.println("Commit title: " + commitTitle);
        }

        String userAuthDetails = getUserAuthDetails();

        RestAdapter.LogLevel logLevel = debug ? RestAdapter.LogLevel.FULL : RestAdapter.LogLevel.NONE;
        RestAdapter stashAdapter = new RestAdapter.Builder().setEndpoint(Config.STASH_REST_BASE).setLogLevel(
                logLevel).build();
        StashService stashService = stashAdapter.create(StashService.class);

        PullRequest pullRequest = new PullRequest();
        pullRequest.setTitle(srcBranch);
        pullRequest.setDescription(commitTitle);

        if (fromUserRepo) {
            String stashUserName = ApiAuthUtil.getUserNameFromAuthString(userAuthDetails);
            pullRequest.setFromRef(ApiHelper.createPullRequestRef(srcBranch, repo, "~" + stashUserName));
        }
        else {
            pullRequest.setFromRef(ApiHelper.createPullRequestRef(srcBranch, repo, Config.STASH_PROJECT_KEY));
        }

        pullRequest.setToRef(ApiHelper.createPullRequestRef(destBranch, repo, Config.STASH_PROJECT_KEY));

        // Set reviewers from user reviewers file
        List<String> reviewersList = ReviewersHelper.getReviewers();

        if (reviewersList == null || reviewersList.isEmpty()) {
            ReviewersHelper.updateReviewersList();
        }

        reviewersList = ReviewersHelper.getReviewers();

        if (reviewersList != null) {
            List<PullRequest.Reviewer> reviewers = new ArrayList<PullRequest.Reviewer>();
            for (String reviewer : reviewersList) {
                reviewers.add(new PullRequest.Reviewer(reviewer.trim()));
                if (debug) {
                    System.out.println("Added reviewer: " + reviewer);
                }
            }
            pullRequest.setReviewers(reviewers);
        }

        try {
            String auth = " Basic " + userAuthDetails;
            PullRequestResponse resp = stashService.createPullRequest(auth, Config.STASH_PROJECT_KEY, repo,
                    pullRequest);
            if (resp != null && resp.getId() != null) {
                System.out.println("Pull request with id: " + resp.getId() + " created!");
                System.out.println("Visit pull request at: " + Config.STASH_HOST + resp.getLink().getUrl());
            }

        }
        catch (Exception e) {
            e.printStackTrace();
            System.exit(1);
        }
    }

    private static void handleJiraIssueTransition(String topicBranch, String targetBranch, String transition, String baseCommit, boolean debug) {
        if (debug) {
            System.out.println("Transitioning JIRA issues found in commits");
            System.out.println("Topic branch: " + topicBranch);
            System.out.println("Target branch: " + targetBranch);
        }

        RestAdapter.LogLevel logLevel = debug ? RestAdapter.LogLevel.FULL : RestAdapter.LogLevel.NONE;
        RestAdapter jiraAdapter = new RestAdapter.Builder().setClient(
                new ApacheClient(getUnsecuredHttpClient())).setEndpoint(
                Config.JIRA_REST_BASE).setLogLevel(logLevel).build();
        JiraService jiraService = jiraAdapter.create(JiraService.class);

        String apiAuth = " Basic " + getUserAuthDetails();

        try {
            Set<String> jiraReferences = GitUtil.getJiraReferencesFromTopicBranch(topicBranch, targetBranch, baseCommit,
                    debug);

            for (String jiraRef : jiraReferences) {
                JiraTransitionsResponse transitionsResponse = jiraService.getJiraIssueTransitions(apiAuth, jiraRef);

                String transitionId;
                if (transition.equals(TransitionIssueCommand.TRANSITION_START_REVIEW)) {
                    transitionId = transitionsResponse.getStartReviewTransitionId();
                    if (transitionId == null) {
                        System.out.println("Start review is not a valid option for: " + jiraRef);
                        continue;
                    }
                }
                else if(transition.equals(TransitionIssueCommand.TRANSITION_COMPLETED)) {
                    transitionId = transitionsResponse.getCompletedTransitionId();
                    if (transitionId == null) {
                        System.out.println("Done/Resolve is not a valid option for: " + jiraRef);
                        continue;
                    }
                }
                else {
                    System.out.println(transition + " is not a valid transition type");
                    continue;
                }

                jiraService.updateJiraIssueState(apiAuth, jiraRef, new JiraTransition(transitionId));
                System.out.println(jiraRef + " transitioned to state: " + transitionsResponse.getTransitionNameFromId(transitionId));
            }
        }
        catch (Exception e) {
            e.printStackTrace();
            System.exit(1);
        }
    }

    private static String getUserAuthDetails() {
        String userAuthDetails = ApiAuthUtil.getUserAuthDetails();
        if (userAuthDetails == null) {
            // Fall back to check user name
            String userName = ApiAuthUtil.getUserName();
            if (userName == null) {
                System.out.println("Can't find auth details or user name.");
                System.out.println("Please set via: git ts set-auth-details");
                System.exit(-1);
            }
            userAuthDetails = ApiAuthUtil.getApiAuthFromUserName(userName);
        }
        return userAuthDetails;
    }

    // Workaround for self-signed JIRA server certs
    private static HttpClient getUnsecuredHttpClient() {
        try {
            SSLContextBuilder builder = new SSLContextBuilder();
            builder.loadTrustMaterial(null, new TrustSelfSignedStrategy());
            SSLConnectionSocketFactory sslsf = new SSLConnectionSocketFactory(
                    builder.loadTrustMaterial(null, new TrustStrategy() {
                        @Override
                        public boolean isTrusted(X509Certificate[] chain, String authType) throws CertificateException {
                            return true;
                        }
                    }).build());
            return HttpClients.custom().setSSLSocketFactory(
                    sslsf).build();
        }
        catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }
}
