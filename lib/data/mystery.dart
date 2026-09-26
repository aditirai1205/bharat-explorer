class Mystery {

  static int reward() {

    List<int> rewards = [
      20,
      10,
      -5,
      3,
      -2,
      0,
    ];

    rewards.shuffle();

    return rewards.first;

  }

}