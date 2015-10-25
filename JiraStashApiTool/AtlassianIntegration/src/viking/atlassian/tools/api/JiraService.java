package viking.atlassian.tools.api;

import viking.atlassian.tools.api.model.JiraTransition;
import viking.atlassian.tools.api.model.JiraTransitionsResponse;
import viking.atlassian.tools.api.model.NoResponse;
import retrofit.http.*;

/**
 * JIRA REST API service.
 *
 * @author Andreas Borglin
 */
public interface JiraService {

    @GET("/issue/{issue}/transitions")
    JiraTransitionsResponse getJiraIssueTransitions(@Header("Authorization") String authorization, @Path("issue") String issue);

    @POST("/issue/{issue}/transitions")
    NoResponse updateJiraIssueState(@Header("Authorization") String authorization, @Path("issue") String issue, @Body
                              JiraTransition transition);
}
