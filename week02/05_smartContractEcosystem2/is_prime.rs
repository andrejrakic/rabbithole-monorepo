use std::env;

fn is_prime(n: u64) -> bool {
    if n <= 1 {
        return false;
    }
    for i in 2..=((n as f64).sqrt() as u64) {
        if n % i == 0 {
            return false;
        }
    }
    true
}

fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() < 2 {
        println!("Usage: {} <number>", args[0]);
        return;
    }

    let number = match args[1].parse::<u64>() {
        Ok(n) => n,
        Err(_) => {
            println!("Please provide a valid number.");
            return;
        },
    };

    // println!("Is {} prime? {}", number, is_prime(number));
    println!("{}", if is_prime(number) { 1 } else { 0 });
}
