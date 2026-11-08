# Diagrama del datapath single-issue (estado actual del proyecto)

> **Actualizado con la Fase 4 completada.** El diagrama definitivo en formato Draw.io está en
> `doc/diagrama_datapath_single_issue.drawio`. Este documento mantiene la versión Mermaid/ASCII
> como respaldo para el informe.

## Respuesta corta

**Sí, el diagrama ya se puede hacer completo** para las cinco etapas: el pipeline single-issue
está implementado hasta la Fase 4 (`datapath_pipeline.v` + `top_pipeline.v`), con el registro
`MEM/WB` y el writeback real desde `MEM_WB_*`.

Lo único que sigue pendiente es la **Fase 6**: forwarding, detección de load-use y los stalls
reales. Esos bloques se dibujan punteados como “pendiente”.

No uses `datapath.v` para este diagrama: ese archivo es el **single-cycle de referencia** que se
restauró. El pipeline está en `src files/datapath_pipeline.v`.

---

## Diagrama de etapas (estado actual, Fase 4)

```mermaid
flowchart LR
    subgraph IF["IF — Fetch"]
        PC["PC"]
        IMEM["imem"]
        PC4["PC + 4"]
    end

    subgraph IFID["IF/ID"]
        RIF["IF_ID_Instr<br/>IF_ID_PC<br/>IF_ID_PC4"]
    end

    subgraph ID["ID — Decode"]
        MD["maindec"]
        AD["aludec"]
        RF["regfile"]
        EXT["extend"]
    end

    subgraph IDEX["ID/EX"]
        RID["ID_EX_*"]
    end

    subgraph EX["EX — Execute"]
        MUXB["mux ALUSrc"]
        ALU["ALU"]
        BR["pcaddbranch"]
        PMUX["mux PC"]
    end

    subgraph EXMEM["EX/MEM"]
        REX["EX_MEM_*"]
    end

    subgraph MEM["MEM — Memory"]
        DMEM["dmem"]
    end

    subgraph MEMWB["MEM/WB"]
        RWB["MEM_WB_*"]
    end

    subgraph WB["WB — Writeback"]
        RMUX["resultmux"]
    end

    PC --> IMEM
    PC --> PC4
    IMEM --> RIF
    PC4 --> RIF
    RIF --> MD
    RIF --> AD
    RIF --> RF
    RIF --> EXT
    MD --> RID
    AD --> RID
    RF --> RID
    EXT --> RID
    RID --> MUXB
    RID --> ALU
    RID --> BR
    MUXB --> ALU
    ALU --> REX
    BR --> PMUX
    REX --> DMEM
    REX --> RWB
    DMEM --> RWB
    RWB --> RMUX
    RMUX --> RF
    PMUX -. "PCNext / flush" .-> PC

    HU["Hazard Unit<br/>(Fase 6: pendiente)"]
    FU["Forwarding Unit<br/>(Fase 6: pendiente)"]
    REX -.-> FU
    RWB -.-> FU
    FU -.-> ALU
    RIF -.-> HU
    RID -.-> HU
    HU -.-> RIF
    HU -.-> RID

    style HU stroke-dasharray: 5 5,stroke:#b85450,fill:#f8cecc
    style FU stroke-dasharray: 5 5,stroke:#b85450,fill:#f8cecc
```

**Leyenda:**

- Líneas sólidas: implementado y verificado (Fases 1–4).
- Líneas punteadas hacia Hazard Unit y Forwarding Unit: Fase 6 pendiente.
- Línea punteada `PCNext / flush`: realimentación de control de EX a IF. El flush de branch ya
  está implementado desde la Fase 3.

---

## Componentes por etapa

| Etapa | Componentes en el proyecto | Archivo |
|-------|----------------------------|---------|
| **IF** | `PC`, `pcadd4`, `imem` | `datapath_pipeline.v`, `top_pipeline.v` |
| **IF/ID** | Registro de instrucción, PC y PC+4 | `ifid.v` |
| **ID** | `maindec`, `aludec`, `regfile`, `extend` | `datapath_pipeline.v` |
| **ID/EX** | Registro de operandos, inmediato, PC, PC+4, rs1/rs2/rd y controles | `idex.v` + `flopenrc.v` |
| **EX** | Mux `ALUSrc`, ALU, `pcaddbranch`, mux de PC | `datapath_pipeline.v` |
| **EX/MEM** | Registro de ALUResult, Zero, WriteData, rd, PC4, PCTarget y controles | `exmem.v` |
| **MEM** | `dmem` (lectura/escritura) | `top_pipeline.v` |
| **MEM/WB** | Registro de ReadData, ALUResult, PC4, rd, RegWrite y ResultSrc | `memwb.v` |
| **WB** | `resultmux` y escritura del `regfile` con `MEM_WB_*` | `datapath_pipeline.v` |

---

## Qué falta para que el diagrama sea el definitivo

| Elemento | Estado | Fase |
|----------|--------|------|
| Registro `MEM/WB` | ✅ Implementado | Fase 4 |
| Writeback desde `MEM_WB_*` | ✅ Implementado | Fase 4 |
| Muxes de forwarding EX/MEM → EX | ❌ Falta | Fase 6 |
| Muxes de forwarding MEM/WB → EX | ❌ Falta | Fase 6 |
| Unidad de detección de load-use | ❌ Falta | Fase 6 |
| `stall_IF_ID` / `stall_ID_EX` reales | ❌ Están a `0` | Fase 6 |
| Flush de branch/jal | ✅ Implementado | Fase 3 |

---

## Versión ASCII (para pegar en el informe si no se renderiza Mermaid)

```text
        ┌──────────────┐   ┌──────────┐   ┌─────────────────────┐   ┌──────────┐
        │ IF / Fetch   │   │  IF/ID   │   │ ID / Decode         │   │  ID/EX   │
        │ PC, imem,    │──▶│ Instr    │──▶│ maindec, aludec,    │──▶│ operandos│
        │ PC+4         │   │ PC, PC+4 │   │ regfile, extend     │   │ controles│
        └──────────────┘   └──────────┘   └─────────────────────┘   └────┬─────┘
                ▲                                                        │
                │ PCNext / flush                                         ▼
        ┌───────┴──────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
        │ EX / Execute │   │ EX/MEM   │   │ MEM      │   │ MEM/WB   │   │ WB       │
        │ mux ALUSrc,  │──▶│ ALUResult│──▶│ dmem     │──▶│ ReadData │──▶│ resultmux│
        │ ALU, branch  │   │ controles│   │          │   │ ALU/PC4  │   │ regfile  │
        └──────────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
```

---

## Recomendación

Para el informe:

1. Usa el archivo **`doc/diagrama_datapath_single_issue.drawio`** para la versión gráfica.
2. Si necesitas pegar texto, usa el diagrama Mermaid o el ASCII de este documento.
3. Aclara en el informe que:
   - **MEM/WB y el writeback ya están implementados** (Fase 4).
   - **Forwarding y load-use están pendientes** (Fase 6), por eso aparecen punteados.
   - El flush de branch sí está implementado (Fase 3).
