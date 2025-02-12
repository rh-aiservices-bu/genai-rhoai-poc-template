# WIP

This repository is a work-in-progress and is not recommended for use in a POC until complete.

## Info

Vanilla configurations for a RHOAI instance to deploy a GenAI POC. This will deploy a variety of different required services including an LLM interface (AnythingLLM), a local S3 bucket, and other services needed for a GenAI POC on RHOAI.

## Deploy POC Scaffolding

Use the [RHDP](https://demo.redhat.com) catalog item named "GenAI POC RHOAI 2025." This catalog item will deploy an OpenShift cluster on AWS with the following configurations:
- publicly trusted TLS keys
- some basic users
- an NVIDIA GPU node
- A few operator installations
  - NVIDIA GPU Operator
  - OpenShift Pipelines
  - OpenShift Serverless (for KServe)
  - OpenShift Service Mesh (for KServe)
  - OpenShift GitOps

OpenShift GitOps is then wired up to use this repository by applying the [bootstrap ApplicationSet](basic-vanilla-poc/bootstrap/applicationset/applicationset-bootstrap.yaml).

At this point, the automation has various gates to control linear roll-out of dependencies.

## Roll-out Explanation

```mermaid
---
title: GenAI RHOAI PoC Roll-out
---
flowchart TD
    subgraph RHOAI
        direction LR
        rhoaiInstall[[Install the Red Hat OpenShift AI Operator]]
        rhoaiDeploy[[Create DataScienceCluster]]
        rhoaiConfig[[Create workbench ImageStreams and other configuration]]
        rhoaiInstall -- before --> rhoaiDeploy -- before --> rhoaiConfig
    end
    demoProject[[Create the Demo project]]
    subgraph MCGW
        direction LR
        mcgwInstall[["Install the Red Hat OpenShift Data Foundation (ODF) Operator"]]
        mcgwDeploy[["Configure ODF to deploy Multi-Cloud Gateway (MCGW) only"]]
        mcgwConfig[[Create an ObjectBucketClaim and RHOAI Data Connection for it]]
        mcgwInstall -- before --> mcgwDeploy -- before --> mcgwConfig
    end
    subgraph userProcess[Model Synchronization]
        modelSync{The model is synchronized from its source, when specified by the user}
    end
    modelDeploy[[Deploy the model using vLLM and KServe, exposing access publicly and requiring token authentication]]
    workbenchPrimer[[Pull the workbench images to nodes in the cluster]]
    deployAnythingLLM[[Create AnythingLLM workbench, pre-wired to use the deployed model as its default LLM provider]]
    pocReady(PoC is ready for you to evaluate the aligned model)
    RHOAI -- before --> MCGW -- before -----> userProcess -- before --> modelDeploy -- before --> deployAnythingLLM
    demoProject -- before --> mcgwConfig
    RHOAI-. before .-> workbenchPrimer-. before .-> deployAnythingLLM
    deployAnythingLLM --> pocReady
```
