fn add(a: i32, b: i32) -> i32 {
    let result = a + b;
    result
}

fn main() {
    let x = 10;
    let y = 20;
    let total = add(x, y);
    println!("total = {}", total);
}
