"""Thread-safe refund processor.

Concurrency model
-----------------
Refunds may arrive concurrently from many threads, possibly targeting the same
order. The invariant ``refunded <= total`` must NEVER be observably violated,
and the sum of all *applied* refund amounts must exactly equal the final
``refunded`` value for every order.

Design
------
Each order gets its own ``threading.Lock``. A refund acquires only that order's
lock, reads ``refunded``, checks whether ``refunded + amount <= total``, and if
so commits the new value -- all inside one critical section. Per-order locking
lets refunds on different orders proceed in parallel while fully serializing
refunds on the same order, which is the only place a race could corrupt the
invariant. The check and commit happen atomically under the lock, so there is
no read-modify-write window in which two threads both observe room and both
commit, overshooting ``total``.
"""

import threading


class Refunder:
    def __init__(self, orders):
        if orders is None:
            raise ValueError("orders must be a dict, not None")

        self._orders = {}
        self._locks = {}

        for order_id, data in orders.items():
            total = data["total"]
            refunded = data.get("refunded", 0.0) if hasattr(data, "get") else data["refunded"]
            self._validate_numeric("total", total)
            self._validate_numeric("refunded", refunded)
            if total < 0:
                raise ValueError(f"total for order {order_id!r} must be >= 0")
            if refunded < 0:
                raise ValueError(f"refunded for order {order_id!r} must be >= 0")
            if refunded > total:
                raise ValueError(
                    f"order {order_id!r} starts with refunded ({refunded}) "
                    f"> total ({total}); invariant already violated"
                )
            self._orders[order_id] = {"total": float(total), "refunded": float(refunded)}
            self._locks[order_id] = threading.Lock()

    @staticmethod
    def _validate_numeric(name, value):
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            raise TypeError(f"{name} must be a real number, got {type(value).__name__}")
        if value != value:
            raise ValueError(f"{name} must not be NaN")
        if value in (float("inf"), float("-inf")):
            raise ValueError(f"{name} must be finite")

    def refund(self, order_id, amount) -> bool:
        if isinstance(amount, bool) or not isinstance(amount, (int, float)):
            return False
        if amount != amount:
            return False
        if amount in (float("inf"), float("-inf")):
            return False
        if amount <= 0:
            return False

        lock = self._locks.get(order_id)
        if lock is None:
            return False

        amount = float(amount)
        with lock:
            order = self._orders[order_id]
            new_refunded = order["refunded"] + amount
            if new_refunded > order["total"]:
                return False
            order["refunded"] = new_refunded
            return True

    def refunded(self, order_id) -> float:
        lock = self._locks.get(order_id)
        if lock is None:
            raise KeyError(order_id)
        with lock:
            return self._orders[order_id]["refunded"]

    def remaining(self, order_id) -> float:
        lock = self._locks.get(order_id)
        if lock is None:
            raise KeyError(order_id)
        with lock:
            order = self._orders[order_id]
            return order["total"] - order["refunded"]
