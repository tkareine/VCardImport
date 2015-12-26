enum ValidationError: ErrorType {
  case Cancelled
  case Empty
  case InvalidURLInput([AnyObject])
}
