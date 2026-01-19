abstract class SearchEvent{}

class Search extends SearchEvent{
  final String term;
  Search(this.term);
}