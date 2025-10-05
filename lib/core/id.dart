String newId([String prefix = 'ev']) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
