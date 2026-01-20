# pqcuark-common

Common SystemVerilog building blocks shared across the PQCUARK hardware project.

## Contents

- `pipe_queue.sv`: Parameterizable pipeline register queue with optional flush.

## Module: pipe_queue

Simple, fixed-latency pipeline for moving a `DATA_WIDTH` word through `PIPE_DEPTH` stages.
The pipeline can be cleared either by active-low reset or by a synchronous flush.

### Parameters

- `DATA_WIDTH`: Width of `data_i`/`data_o` in bits.
- `PIPE_DEPTH`: Number of pipeline stages (latency in cycles).

### Ports

- `clk_i`: Clock.
- `rstn_i`: Active-low asynchronous reset.
- `flush_i`: Synchronous flush; clears all stages when asserted.
- `data_i`: Input data.
- `data_o`: Output data from the last stage.

### Example

```systemverilog
pipe_queue #(
  .DATA_WIDTH(64),
  .PIPE_DEPTH(3)
) u_pipe_queue (
  .clk_i   (clk),
  .rstn_i  (rstn),
  .flush_i (flush_pipe),
  .data_i  (in_data),
  .data_o  (out_data)
);
```

## Integration

This repository is used as a submodule in the PQCUARK top-level project. If you are
adding a new common module, keep the interface minimal and add a short usage example
here so other blocks can adopt it quickly.

## Contributing

Keep modules parameterizable, follow the existing naming conventions, and document
reset/flush behavior explicitly in the module header.
