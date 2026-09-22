type User = { name: string; age: number };

function greet(user: User): string {
  return `Hello, ${user.name}`;
}

const user: User = {
  name: "Azaria",
  age: 20,
};

console.log(greet(user));
