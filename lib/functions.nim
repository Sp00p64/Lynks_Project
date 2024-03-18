proc isEmptyString*(s: string): bool =
  for c in s:
    if c != '\0':
      return false
  return true