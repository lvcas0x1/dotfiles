package com.example;

public class Main {
  public static int add(int a, int b) {
    int result = a + b;
    return result;
  }

  public static void main(String[] args) {
    int x = 10;
    int y = 20;
    int total = add(x, y);

    System.out.println("total = " + total);
  }
}
