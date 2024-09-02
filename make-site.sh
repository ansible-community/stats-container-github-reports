#!/usr/bin/bash

quarto render && \
	rm -rf output/* && \
	cp -Tr github/ output/
