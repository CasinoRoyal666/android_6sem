abstract class NavigationEvent {}

class NavigateToPageEvent extends NavigationEvent {
  final int pageIndex;

  NavigateToPageEvent(this.pageIndex);
}