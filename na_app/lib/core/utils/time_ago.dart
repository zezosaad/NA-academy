String timeAgo(DateTime dateTime, {bool arabic = true}) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.inSeconds < 60) return arabic ? 'الآن' : 'just now';
  
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    if (arabic) {
      if (m == 1) return 'منذ دقيقة';
      if (m == 2) return 'منذ دقيقتين';
      if (m >= 3 && m <= 10) return 'منذ $m دقائق';
      return 'منذ $m دقيقة';
    }
    return '$m ${m == 1 ? 'min' : 'mins'} ago';
  }
  
  if (diff.inHours < 24) {
    final h = diff.inHours;
    if (arabic) {
      if (h == 1) return 'منذ ساعة';
      if (h == 2) return 'منذ ساعتين';
      if (h >= 3 && h <= 10) return 'منذ $h ساعات';
      return 'منذ $h ساعة';
    }
    return '$h ${h == 1 ? 'hour' : 'hours'} ago';
  }
  
  if (diff.inDays < 7) {
    final d = diff.inDays;
    if (arabic) {
      if (d == 1) return 'منذ يوم';
      if (d == 2) return 'منذ يومين';
      if (d >= 3 && d <= 10) return 'منذ $d أيام';
      return 'منذ $d يوم';
    }
    return '$d ${d == 1 ? 'day' : 'days'} ago';
  }
  
  if (diff.inDays < 30) {
    final w = (diff.inDays / 7).floor();
    if (arabic) {
      if (w == 1) return 'منذ أسبوع';
      if (w == 2) return 'منذ أسبوعين';
      return 'منذ $w أسابيع';
    }
    return '$w ${w == 1 ? 'week' : 'weeks'} ago';
  }
  
  final months = (diff.inDays / 30).floor();
  if (arabic) {
    if (months == 1) return 'منذ شهر';
    if (months == 2) return 'منذ شهرين';
    return 'منذ $months أشهر';
  }
  return '$months ${months == 1 ? 'month' : 'months'} ago';
}
