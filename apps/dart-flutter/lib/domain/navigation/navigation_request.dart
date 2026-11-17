import '../models/directory_path.dart';

/// How the user wants to move; resolved against the history by the view model.
sealed class NavigationRequest {
  const NavigationRequest();
}

final class VisitRequest extends NavigationRequest {
  const VisitRequest(this.destination);
  final DirectoryPath destination;
}

final class BackRequest extends NavigationRequest {
  const BackRequest();
}

final class ForwardRequest extends NavigationRequest {
  const ForwardRequest();
}

final class UpRequest extends NavigationRequest {
  const UpRequest();
}

final class RefreshRequest extends NavigationRequest {
  const RefreshRequest();
}
