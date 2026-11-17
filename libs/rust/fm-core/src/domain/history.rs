use super::DirectoryPath;

/// Aggregate root of a browsing session: where the user is, and where they
/// can go back or forward to. Pure state machine, trivially testable.
///
/// Navigation is two-phase so that failed loads never corrupt the history:
/// callers *peek* a destination, try to load it, and only *commit* on success.
#[derive(Debug, Clone)]
pub struct NavigationHistory {
    current: DirectoryPath,
    back: Vec<DirectoryPath>,
    forward: Vec<DirectoryPath>,
}

impl NavigationHistory {
    pub fn new(start: DirectoryPath) -> Self {
        Self { current: start, back: Vec::new(), forward: Vec::new() }
    }

    pub fn current(&self) -> &DirectoryPath {
        &self.current
    }

    pub fn can_go_back(&self) -> bool {
        !self.back.is_empty()
    }

    pub fn can_go_forward(&self) -> bool {
        !self.forward.is_empty()
    }

    pub fn can_go_up(&self) -> bool {
        !self.current.is_root()
    }

    pub fn peek_back(&self) -> Option<&DirectoryPath> {
        self.back.last()
    }

    pub fn peek_forward(&self) -> Option<&DirectoryPath> {
        self.forward.last()
    }

    /// Commits a brand-new visit (clears the forward stack).
    pub fn visit(&mut self, destination: DirectoryPath) {
        if destination == self.current {
            return;
        }
        let previous = std::mem::replace(&mut self.current, destination);
        self.back.push(previous);
        self.forward.clear();
    }

    /// Commits a step back. Returns `false` when there is nowhere to go.
    pub fn go_back(&mut self) -> bool {
        let Some(destination) = self.back.pop() else { return false };
        let previous = std::mem::replace(&mut self.current, destination);
        self.forward.push(previous);
        true
    }

    /// Commits a step forward. Returns `false` when there is nowhere to go.
    pub fn go_forward(&mut self) -> bool {
        let Some(destination) = self.forward.pop() else { return false };
        let previous = std::mem::replace(&mut self.current, destination);
        self.back.push(previous);
        true
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn p(s: &str) -> DirectoryPath {
        DirectoryPath::new(s).unwrap()
    }

    #[test]
    fn back_and_forward_round_trip() {
        let mut h = NavigationHistory::new(p("/a"));
        h.visit(p("/a/b"));
        h.visit(p("/a/b/c"));
        assert!(h.go_back());
        assert_eq!(h.current(), &p("/a/b"));
        assert!(h.go_forward());
        assert_eq!(h.current(), &p("/a/b/c"));
        assert!(!h.can_go_forward());
    }

    #[test]
    fn new_visit_clears_forward_stack() {
        let mut h = NavigationHistory::new(p("/a"));
        h.visit(p("/b"));
        h.go_back();
        h.visit(p("/c"));
        assert!(!h.can_go_forward());
        assert_eq!(h.peek_back(), Some(&p("/a")));
    }

    #[test]
    fn visiting_current_location_is_a_no_op() {
        let mut h = NavigationHistory::new(p("/a"));
        h.visit(p("/a"));
        assert!(!h.can_go_back());
    }
}
