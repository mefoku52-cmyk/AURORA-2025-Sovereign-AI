#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TRIMOST – Tri-Mostový Meta-Kernel
---------------------------------

ÚČEL:
- Prepojiť tri hlavné subsystémy:
    1. RadoslavEntity (kognitívna vrstva)
    2. KOMETA microkernel (technická vrstva)
    3. AIOSKernel / AURORA (systémová vrstva)

- TRIMOST nie je pasívny router.
  Je to rozhodovací orgán, ktorý:
    • analyzuje vstup
    • vypočíta váhy
    • rozhodne, koho sa opýtať
    • vyhodnotí odpovede
    • preverí ich logiku
    • rozhodne, čo poslať do jadra
    • čaká na odpoveď
    • validuje odpoveď
    • vráti finálne rozhodnutie

TRIMOST = dobrý priateľ, ale veľmi zlý nepriateľ.
"""

import time
import json
from dataclasses import dataclass, field
from typing import Any, Dict, Optional, Callable, Awaitable


# ============================================================
# 1. TELEMETRIA
# ============================================================

@dataclass
class TelemetryRecord:
    timestamp: float
    stimulus: Dict[str, Any]
    weights: Dict[str, float]
    radoslav_called: bool
    kometa_called: bool
    kernel_called: bool
    radoslav_result: Optional[Dict[str, Any]] = None
    kometa_result: Optional[Dict[str, Any]] = None
    kernel_result: Optional[Dict[str, Any]] = None
    final_decision: str = "NO_DECISION"
    final_reason: str = ""


class Telemetry:
    def __init__(self, max_records: int = 500):
        self.max = max_records
        self.records = []

    def add(self, rec: TelemetryRecord):
        self.records.append(rec)
        if len(self.records) > self.max:
            self.records.pop(0)

    def dump(self):
        return json.dumps([r.__dict__ for r in self.records], ensure_ascii=False, indent=2)


# ============================================================
# 2. VÁHOVÝ ANALYZÁTOR
# ============================================================

class WeightAnalyzer:
    """
    Rozhoduje, ktorá vrstva má najväčší význam.
    """

    @staticmethod
    def compute(stimulus: Dict[str, Any]) -> Dict[str, float]:
        text = str(stimulus.get("content", "")).lower()
        source = str(stimulus.get("source", "unknown")).lower()

        w_cog = 0.0
        w_tech = 0.0
        w_sys = 0.0

        # Kognitívne signály
        if any(x in text for x in ["prečo", "ako", "myslím", "bojím", "chcem", "cítim"]):
            w_cog += 0.5
        if source in ("human", "user", "self"):
            w_cog += 0.3

        # Technické signály
        if any(x in text for x in ["model", "embedding", "vector", "latency", "cpu"]):
            w_tech += 0.5
        if source in ("sensor", "telemetry"):
            w_tech += 0.2

        # Systémové signály
        if any(x in text for x in ["kernel", "sentinel", "exec", "script", "integrity"]):
            w_sys += 0.6
        if source in ("system", "aos", "aurora"):
            w_sys += 0.3

        return {
            "cognitive": min(1.0, w_cog),
            "technical": min(1.0, w_tech),
            "system": min(1.0, w_sys),
        }


# ============================================================
# 3. TRIMOST – HLAVNÝ MOZOG
# ============================================================

class TRIMOST:
    def __init__(
        self,
        radoslav_entity: Any,
        kometa_dispatch: Callable[[str, Dict[str, Any]], Awaitable[Dict[str, Any]]],
        kernel_status: Callable[[], Awaitable[Dict[str, Any]]],
        kernel_action: Callable[[str], Awaitable[Dict[str, Any]]],
    ):
        """
        radoslav_entity.process_environment(stimulus) -> dict
        kometa_dispatch(model_id, payload) -> dict
        kernel_status() -> dict
        kernel_action("sentinel" | "integrity") -> dict
        """
        self.radoslav = radoslav_entity
        self.kometa = kometa_dispatch
        self.kernel_status = kernel_status
        self.kernel_action = kernel_action
        self.telemetry = Telemetry()

    # --------------------------------------------------------
    # HLAVNÝ ROZHODOVACÍ CYKLUS
    # --------------------------------------------------------
    async def process(self, stimulus: Dict[str, Any]) -> Dict[str, Any]:
        weights = WeightAnalyzer.compute(stimulus)

        rec = TelemetryRecord(
            timestamp=time.time(),
            stimulus=stimulus,
            weights=weights,
            radoslav_called=False,
            kometa_called=False,
            kernel_called=False,
        )

        # 1. Kognitívna vrstva
        if weights["cognitive"] >= 0.3:
            rec.radoslav_called = True
            rec.radoslav_result = self.radoslav.process_environment(stimulus)

        # 2. Technická vrstva
        if weights["technical"] >= 0.3:
            rec.kometa_called = True
            rec.kometa_result = await self.kometa("HealthCheckModel", {})

        # 3. Systémová vrstva
        if weights["system"] >= 0.3:
            rec.kernel_called = True
            rec.kernel_result = await self.kernel_status()

        # --------------------------------------------------------
        # 4. ROZHODOVANIE (bez zacyklenia)
        # --------------------------------------------------------

        decision, reason = self._decide(rec)
        rec.final_decision = decision
        rec.final_reason = reason

        # 5. Ak treba zásah jadra
        if decision == "SYSTEM_ACTION":
            action_result = await self.kernel_action("sentinel")
            rec.kernel_result = action_result

        # 6. Uložiť telemetriu
        self.telemetry.add(rec)

        # 7. Vrátiť finálny výsledok
        return {
            "decision": rec.final_decision,
            "reason": rec.final_reason,
            "radoslav": rec.radoslav_result,
            "kometa": rec.kometa_result,
            "kernel": rec.kernel_result,
            "weights": rec.weights,
        }

    # --------------------------------------------------------
    # 5. ROZHODOVACIA LOGIKA
    # --------------------------------------------------------
    def _decide(self, rec: TelemetryRecord) -> (str, str):
        """
        TRIMOST rozhoduje podľa:
        - váh
        - hrozby z Radoslava
        - technického stavu z KOMETY
        - systémového stavu z jadra
        """

        w = rec.weights

        # 1. Ak systémová vrstva kričí → priorita
        if rec.kernel_result:
            stagn = rec.kernel_result.get("db_state", {}).get("stagnation_cycles")
            if stagn and int(stagn) > 2:
                return "SYSTEM_ACTION", "Kernel stagnation detected"

        # 2. Ak Radoslav hlási vysokú hrozbu
        if rec.radoslav_result:
            threat = rec.radoslav_result["threat"]["level"]
            if threat > 0.7:
                return "CONFRONT", "High cognitive threat"

        # 3. Ak technická vrstva hlási problém
        if rec.kometa_result:
            if rec.kometa_result.get("models_active", 0) < 10:
                return "SYSTEM_ACTION", "Technical subsystem degraded"

        # 4. Inak podľa váh
        if w["cognitive"] > w["technical"] and w["cognitive"] > w["system"]:
            return "OBSERVE", "Cognitive dominance"

        if w["technical"] > w["cognitive"] and w["technical"] > w["system"]:
            return "NO_ACTION", "Technical info only"

        if w["system"] > 0.5:
            return "SYSTEM_ACTION", "System-level event"

        return "NO_ACTION", "No significant signal"
