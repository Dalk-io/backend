class Migration {
  final int version;
  final List<String> sqlCommands;

  const Migration(this.version, this.sqlCommands);
}
