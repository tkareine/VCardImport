struct SelectionOption<T> {
  let data: T
  let shortDescription: String
  let longDescription: String?

  init(data: T, shortDescription: String, longDescription: String? = nil) {
    self.data = data
    self.shortDescription = shortDescription
    self.longDescription = longDescription
  }
}
