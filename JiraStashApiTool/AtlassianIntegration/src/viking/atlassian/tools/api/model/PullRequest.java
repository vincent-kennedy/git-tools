package viking.atlassian.tools.api.model;

import java.util.List;

/**
 * Pull request model.
 * @author Andreas Borglin
 */
public class PullRequest {

    public static class Project {
        private String key;

        public Project() {
        }

        public Project(String key) {
            this.key = key;
        }

        public String getKey() {
            return key;
        }

        public void setKey(String key) {
            this.key = key;
        }
    }

    public static class Repository {
        private String slug;
        private String name;
        private Project project;

        public Repository() {

        }
        public Repository(String slug, String name, String projectKey) {
            this.slug = slug;
            this.name = name;
            this.project = new Project(projectKey);
        }

        public String getSlug() {
            return slug;
        }

        public void setSlug(String slug) {
            this.slug = slug;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public Project getProject() {
            return project;
        }

        public void setProject(Project project) {
            this.project = project;
        }
    }

    public static class Ref {
        private String id;
        private Repository repository;

        public Ref() {

        }

        public Ref(String id, Repository repo) {
            this.id = id;
            this.repository = repo;
        }

        public String getId() {
            return id;
        }

        public void setId(String id) {
            this.id = id;
        }

        public Repository getRepository() {
            return repository;
        }

        public void setRepository(Repository repository) {
            this.repository = repository;
        }
    }

    public static class User {
        private String name;

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }
    }

    public static class Reviewer {

        public Reviewer() {

        }

        public Reviewer(String userName) {
            user = new User();
            user.setName(userName);
        }

        private User user;

        public User getUser() {
            return user;
        }

        public void setUser(User user) {
            this.user = user;
        }
    }

    private String title;
    private String description;
    private String state = "OPEN";
    private boolean open = true;
    private boolean closed = false;
    private Ref fromRef;
    private Ref toRef;
    private List<Reviewer> reviewers;

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getState() {
        return state;
    }

    public void setState(String state) {
        this.state = state;
    }

    public boolean isOpen() {
        return open;
    }

    public void setOpen(boolean open) {
        this.open = open;
    }

    public boolean isClosed() {
        return closed;
    }

    public void setClosed(boolean closed) {
        this.closed = closed;
    }

    public Ref getFromRef() {
        return fromRef;
    }

    public void setFromRef(Ref fromRef) {
        this.fromRef = fromRef;
    }

    public Ref getToRef() {
        return toRef;
    }

    public void setToRef(Ref toRef) {
        this.toRef = toRef;
    }

    public List<Reviewer> getReviewers() {
        return reviewers;
    }

    public void setReviewers(List<Reviewer> reviewers) {
        this.reviewers = reviewers;
    }
}
