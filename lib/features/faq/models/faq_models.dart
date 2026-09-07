/// A single FAQ entry.
class FaqItem {
  const FaqItem(this.question, this.answer);
  final String question;
  final String answer;
}

/// A labelled group of FAQ entries ("Money", "Rules", "Account").
class FaqSection {
  const FaqSection(this.title, this.items);
  final String title;
  final List<FaqItem> items;
}
