abstract class Endpoint<Input, Output> {
  Future<Output> request(Input input);
}
