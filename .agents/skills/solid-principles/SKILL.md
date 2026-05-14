---
name: solid-principles
user-invocable: false
description: Use during implementation when designing modules, functions, and components requiring SOLID principles for maintainable, flexible architecture.
allowed-tools:
  - Read
  - Edit
  - Grep
  - Glob
---

# SOLID Principles

Apply SOLID design principles for maintainable, flexible code architecture.

## The Five Principles

### 1. Single Responsibility Principle (SRP)

**A module should have one, and only one, reason to change**

### Dart Pattern

```dart
// BAD - Multiple responsibilities
class UserManager {
  void createUser(Map<String, dynamic> data) {
    // Creates user
    // Sends welcome email
    // Logs to analytics
    // Updates cache
  }
}

// GOOD - Single responsibility
class UserRepository {
  void createUser(Map<String, dynamic> data) {
    // Database insert only
  }
}

class UserNotifier {
  void sendWelcomeEmail(User user) {
    // Email logic only
  }
}

class UserAnalytics {
  void trackSignup(User user) {
    // Analytics logic only
  }
}
```

**Ask yourself:** "What is the ONE thing this module does?"

### 2. Open/Closed Principle (OCP)

**Software entities should be open for extension, closed for modification.**

### Dart Pattern

```dart
// BAD - Requires modification for new types
class PaymentProcessor {
  void processPayment(String type, double amount) {
    if (type == 'stripe') {
      // Stripe logic
    } else if (type == 'paypal') {
      // PayPal logic
    }
    // Have to modify this method for new providers
  }
}

// GOOD - Extension through polymorphism
abstract class PaymentProvider {
  void processPayment(double amount);
}

class StripeProvider implements PaymentProvider {
  @override
  void processPayment(double amount) {
    // Stripe logic
  }
}

class PayPalProvider implements PaymentProvider {
  @override
  void processPayment(double amount) {
    // PayPal logic
  }
}

class PaymentProcessor {
  void charge(PaymentProvider provider, double amount) {
    provider.processPayment(amount); // Open for extension, closed for modification
  }
}
```

**Ask yourself:** "Can I add new functionality without changing existing code?"

### 3. Liskov Substitution Principle (LSP)

**Subtypes must be substitutable for their base types**

### Dart Pattern

```dart
// BAD - Violates LSP
class Bird {
  void fly() {
    print('Flying');
  }
}

class Penguin extends Bird {
  @override
  void fly() {
    throw Exception('Penguins cannot fly'); // Breaks contract
  }
}

// GOOD - Correct abstraction
abstract class Bird {
  void move();
}

abstract class FlyingBird extends Bird {
  void fly();
}

class Sparrow extends FlyingBird {
  @override
  void move() => fly();
  
  @override
  void fly() => print('Flying');
}

class Penguin extends Bird {
  @override
  void move() => swim();
  
  void swim() => print('Swimming');
}
```

**Ask yourself:** "Can I replace this with its parent/interface without breaking behavior?"

### 4. Interface Segregation Principle (ISP)

**Clients should not be forced to depend on interfaces they don't use.**

### Dart Pattern

```dart
// BAD - Fat interface
abstract class UserWorker {
  void work();
  void takeBreak();
  void clockIn();
  void clockOut();
  void receiveBenefits();
  // Not all workers need all methods
}

// GOOD - Segregated interfaces
abstract class Workable {
  void work();
}

abstract class TimeTrackable {
  void clockIn();
  void clockOut();
}

abstract class BenefitsEligible {
  void receiveBenefits();
}

// Compose only what you need
class FullTimeEmployee implements Workable, TimeTrackable, BenefitsEligible {
  @override void work() {}
  @override void clockIn() {}
  @override void clockOut() {}
  @override void receiveBenefits() {}
}

class ContractWorker implements Workable, TimeTrackable {
  @override void work() {}
  @override void clockIn() {}
  @override void clockOut() {}
}
```

**Ask yourself:** "Does this interface force implementations to define unused methods?"

### 5. Dependency Inversion Principle (DIP)

**Depend on abstractions, not concretions**

### Dart Pattern

```dart
// BAD - Direct dependency on implementation
class StripeApi {
  void charge(double amount) {}
}

class UserManager {
  final StripeApi _api = StripeApi(); // Tightly coupled

  void processPayment(double amount) {
    _api.charge(amount);
  }
}

// GOOD - Depend on abstraction
abstract class PaymentApi {
  void charge(double amount);
}

class StripeApiImpl implements PaymentApi {
  @override
  void charge(double amount) {}
}

class UserManager {
  final PaymentApi paymentApi; // Injected dependency

  UserManager(this.paymentApi);

  void processPayment(double amount) {
    paymentApi.charge(amount);
  }
}
```

**Ask yourself:** "Can I swap implementations without changing dependent code?"

## Application Checklist

### Before writing new code

- [ ] Identify the single responsibility
- [ ] Design for extension points (interfaces/abstract classes)
- [ ] Define abstractions before implementations
- [ ] Keep interfaces minimal and focused

### During implementation

- [ ] Each module has ONE reason to change (SRP)
- [ ] New features extend, don't modify (OCP)
- [ ] Implementations honor contracts (LSP)
- [ ] Interfaces are minimal (ISP)
- [ ] Dependencies are injected/configurable (DIP)

### During code review

- [ ] Are responsibilities clearly separated?
- [ ] Can we add features without modifying existing code?
- [ ] Do all implementations fulfill their contracts?
- [ ] Are interfaces focused and minimal?
- [ ] Are dependencies abstracted?

## Common Violations in Codebase

### SRP Violation
- Widgets that fetch data AND render (use BLoC, Riverpod, or separated view models).

### OCP Violation
- Long switch statements for handling different types (use polymorphism).

### LSP Violation
- Throwing `UnimplementedError` for methods enforced by an overly broad interface.

### ISP Violation
- Massive base classes or fat interfaces that force widgets/models to implement unnecessary methods.

### DIP Violation
- Direct instantiations of Repositories inside Widgets instead of using Dependency Injection (like get_it or provider).

## Integration with Existing Skills

### Works with
- `boy-scout-rule`: Apply SOLID when improving code
- `test-driven-development`: Write tests for each responsibility

## Remember

**SOLID is about managing dependencies and responsibilities, not about creating more code.**

Good design emerges from applying these principles pragmatically, not dogmatically.
