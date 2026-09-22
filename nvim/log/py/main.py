import os
import sys


def add(a: int, b: int) -> int:
    result = a + b
    return result


def main() -> None:
    x = 10
    y = 20
    total = add(x, y)

    print(f"total = {total}")
    print(os.getcwd())
    print(sys.version)


if __name__ == "__main__":
    main()
