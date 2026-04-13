# Example: OOP Review — Order Processing

## Submitted Code

```python
def process_order(order_id, user_id, items, coupon_code, shipping_address, billing_address):
    user = db.query(f"SELECT * FROM users WHERE id = {user_id}")
    if not user:
        return {"error": "user not found"}

    order_items = []
    total = 0
    for item in items:
        product = db.query(f"SELECT * FROM products WHERE id = {item['id']}")
        if product['stock'] < item['quantity']:
            return {"error": f"insufficient stock for {product['name']}"}
        price = product['price'] * item['quantity']
        if coupon_code == "SAVE10":
            price = price * 0.9
        elif coupon_code == "SAVE20":
            price = price * 0.8
        total += price
        order_items.append({"product_id": item['id'], "quantity": item['quantity'], "price": price})

    # save order to database
    order = db.execute(
        "INSERT INTO orders (user_id, total, shipping_address, billing_address) VALUES (?, ?, ?, ?)",
        user_id, total, shipping_address, billing_address
    )
    for oi in order_items:
        db.execute("INSERT INTO order_items ...", oi)

    # send confirmation email
    email_body = f"Dear {user['name']}, your order total is {total}."
    send_email(user['email'], "Order Confirmed", email_body)

    return {"order_id": order.id, "total": total}
```

---

## Section 1 — Executive Architectural Summary

This is an object-oriented Python codebase operating without objects. The function carries every responsibility in the order lifecycle — validation, pricing, persistence, and notification — compressed into a single 30-line procedure. The foundation is salvageable: the business intent is clear, and the logic is mostly correct. What follows is a path toward a design that can grow without accumulating debt.

---

## Section 2 — Deep Structural Diagnosis

The most immediately visible problem is the violation of Single Responsibility at the function level. `process_order` does four distinct things: it validates inputs, it calculates pricing, it persists data, and it triggers a notification. Each of these is a reason to change the function — a pricing policy change, a database schema migration, a new notification channel — and they are completely unrelated to each other. This is a textbook God Function, the procedural equivalent of a God Class.

Beneath the structural problem lies Primitive Obsession of significant severity. The coupon logic is a direct symptom: a bare string is compared against hardcoded constants to determine discount rates. There is no concept of a `Coupon` or `DiscountPolicy` in this codebase — just string literals scattered across the flow. When a third coupon type is introduced, this conditional grows. When a percentage changes, it must be found and edited in place. The business concept exists, but it has no home.

The SQL string interpolation (`f"SELECT * FROM users WHERE id = {user_id}"`) introduces a SQL injection vulnerability, which technically violates Beck's Rule 1 (Correctness) before anything else can be discussed. This must be addressed before any other refactoring.

Finally, the comment `# save order to database` and `# send confirmation email` are design smells per DHH's expressiveness principles. They are compensating for the method's refusal to name its own intentions. Extracting those blocks into methods named `persist_order` and `notify_customer` would make the comments redundant — and reveal the structure that's already implicit in the code.

---

## Section 3 — Operational Refactoring Plan

**Step 1 — Eliminate the SQL injection (Correctness, Rule 1)**
Replace all string-interpolated queries with parameterized queries. This is a precondition for everything else.

**Step 2 — Extract a `Coupon` Value Object (Primitive Obsession)**
Create a `Coupon` class that knows its own discount rate. The conditional `if coupon_code == "SAVE10"` disappears. `Coupon.from_code("SAVE10").apply(price)` replaces the branching logic. New coupon types are added by registering new instances, not by editing the processing function.

**Step 3 — Extract `calculate_line_item_price` and `validate_stock` (Metz: Lines per Method)**
Each loop body currently handles two responsibilities: validation and pricing. Extract them into named methods. The loop body becomes two readable calls.

**Step 4 — Extract `persist_order` and `notify_customer` (DHH: Comments as Smells)**
Move the database writes and email dispatch into private methods. The top-level function becomes an orchestrator that reads like a domain narrative.

**Step 5 — Inject dependencies (Dependency Inversion)**
Pass `db` and `email_service` as parameters or constructor arguments. This makes the function testable without a live database or mail server.

---

## Section 4 — Refactored Code

```python
from dataclasses import dataclass
from decimal import Decimal
from typing import Optional

COUPONS = {
    "SAVE10": Decimal("0.90"),
    "SAVE20": Decimal("0.80"),
}

@dataclass(frozen=True)
class Coupon:
    code: str
    multiplier: Decimal

    @classmethod
    def from_code(cls, code: Optional[str]) -> "Coupon":
        multiplier = COUPONS.get(code, Decimal("1.0"))
        return cls(code=code or "", multiplier=multiplier)

    def apply(self, price: Decimal) -> Decimal:
        return price * self.multiplier


class OrderProcessor:
    def __init__(self, db, email_service):
        self.db = db
        self.email_service = email_service

    def process(self, order_id, user_id, items, coupon_code, shipping_address, billing_address):
        user = self._find_user(user_id)
        coupon = Coupon.from_code(coupon_code)
        order_items, total = self._build_order_items(items, coupon)
        order = self._persist_order(user_id, total, order_items, shipping_address, billing_address)
        self._notify_customer(user, total)
        return {"order_id": order.id, "total": total}

    def _find_user(self, user_id):
        user = self.db.query("SELECT * FROM users WHERE id = ?", user_id)
        if not user:
            raise ValueError(f"User {user_id} not found")
        return user

    def _build_order_items(self, items, coupon):
        order_items = []
        total = Decimal("0")
        for item in items:
            product = self.db.query("SELECT * FROM products WHERE id = ?", item["id"])
            self._assert_sufficient_stock(product, item["quantity"])
            line_price = coupon.apply(product["price"] * item["quantity"])
            total += line_price
            order_items.append({"product_id": item["id"], "quantity": item["quantity"], "price": line_price})
        return order_items, total

    def _assert_sufficient_stock(self, product, requested_quantity):
        if product["stock"] < requested_quantity:
            raise ValueError(f"Insufficient stock for {product['name']}")

    def _persist_order(self, user_id, total, order_items, shipping_address, billing_address):
        order = self.db.execute(
            "INSERT INTO orders (user_id, total, shipping_address, billing_address) VALUES (?, ?, ?, ?)",
            user_id, total, shipping_address, billing_address,
        )
        for item in order_items:
            self.db.execute("INSERT INTO order_items ...", item)
        return order

    def _notify_customer(self, user, total):
        self.email_service.send(
            to=user["email"],
            subject="Order Confirmed",
            body=f"Dear {user['name']}, your order total is {total}.",
        )
```
