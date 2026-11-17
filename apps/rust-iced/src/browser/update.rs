use fm_core::domain::DirectoryPath;
use iced::Task;

use super::message::{LoadOutcome, Message, Navigation};
use super::state::{Browser, Phase};

impl Browser {
    pub fn update(&mut self, message: Message) -> Task<Message> {
        match message {
            Message::Navigate(navigation) => self.navigate(navigation),
            Message::Loaded(outcome) => {
                self.apply_load(outcome);
                Task::none()
            }
            Message::Select(path) => {
                self.selected = Some(path);
                Task::none()
            }
            Message::Activate(path) => self.activate(&path),
            Message::HoverEnter(path) => {
                self.hovered = Some(path);
                Task::none()
            }
            Message::HoverExit(path) => {
                if self.hovered.as_ref() == Some(&path) {
                    self.hovered = None;
                }
                Task::none()
            }
            Message::MoveSelection(delta) => {
                self.move_selection(delta);
                Task::none()
            }
            Message::ActivateSelection => match self.selected.clone() {
                Some(path) => self.activate(&path),
                None => Task::none(),
            },
            Message::ToggleHidden => {
                self.visibility = self.visibility.toggled();
                Task::none()
            }
            Message::DismissError => {
                self.error = None;
                Task::none()
            }
        }
    }

    /// Resolves where a navigation leads and starts loading it in the
    /// background. History is only committed once the load succeeds.
    pub(super) fn navigate(&mut self, navigation: Navigation) -> Task<Message> {
        let destination = match &navigation {
            Navigation::Visit(path) => Some(path.clone()),
            Navigation::Back => self.history.peek_back().cloned(),
            Navigation::Forward => self.history.peek_forward().cloned(),
            Navigation::Up => self.history.current().parent(),
            Navigation::Refresh => Some(self.history.current().clone()),
        };
        let Some(destination) = destination else { return Task::none() };

        self.ticket += 1;
        self.phase = Phase::Loading;
        let ticket = self.ticket;
        let browse = self.browse.clone();

        // The use case is synchronous; iced runs futures on its thread pool,
        // so the UI thread never blocks on disk I/O.
        Task::perform(async move { browse.execute(&destination) }, move |result| {
            Message::Loaded(LoadOutcome { ticket, navigation: navigation.clone(), result })
        })
    }

    fn apply_load(&mut self, outcome: LoadOutcome) {
        if outcome.ticket != self.ticket {
            return; // A newer navigation superseded this one.
        }
        self.phase = Phase::Ready;
        match outcome.result {
            Ok(listing) => {
                let destination = listing.path().clone();
                match outcome.navigation {
                    Navigation::Visit(_) | Navigation::Up => self.history.visit(destination),
                    Navigation::Back => _ = self.history.go_back(),
                    Navigation::Forward => _ = self.history.go_forward(),
                    Navigation::Refresh => {}
                }
                self.selected = None;
                self.hovered = None;
                self.error = None;
                self.listing = Some(listing);
            }
            Err(error) => self.error = Some(error),
        }
    }

    fn activate(&mut self, path: &std::path::PathBuf) -> Task<Message> {
        let Some(entry) = self.entry(path) else { return Task::none() };
        if !entry.is_navigable() {
            // Opening files is out of scope for this first draft.
            self.selected = Some(path.clone());
            return Task::none();
        }
        match DirectoryPath::new(entry.path.clone()) {
            Some(destination) => self.navigate(Navigation::Visit(destination)),
            None => Task::none(),
        }
    }

    fn move_selection(&mut self, delta: isize) {
        let entries = self.visible_entries();
        if entries.is_empty() {
            return;
        }
        let current = self
            .selected
            .as_ref()
            .and_then(|s| entries.iter().position(|e| &e.path == s));
        let last = entries.len() - 1;
        let next = match current {
            None => 0,
            Some(i) => i.saturating_add_signed(delta).min(last),
        };
        self.selected = Some(entries[next].path.clone());
    }
}
