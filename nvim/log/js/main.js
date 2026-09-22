function add(a, b) {
  const result = a + b;
  return result;
}

function multiply(a, b) {
  const result = a * b;
  return result;
}

function calculate(x, y) {
  const sum = add(x, y);
  const product = multiply(x, y);

  return {
    sum,
    product,
  };
}

function main() {
  const x = 10;
  const y = 20;

  const result = calculate(x, y);

  console.log(`sum = ${result.sum}`);
  console.log(`product = ${result.product}`);
}

main();
