# TP termotanque - Assembler
*Este repositorio contiene un programa hecho en Assembler para un Trabajo Práctico de Arquitectura de Computadoras. 
  Se trata de programar el microcontrolador PIC16F628A para que simule el funcionamiento de un termotanque, el nivel del agua y su temperatura. Se implementa el uso de los LEDS
del puerto B para poder visualizarlo en el simulador Proteus. El código se encuentra en el archivo .asm y el diagrama de flujo en el png
  Esta construído en Assembler con la ide MPLAB*

  
El funcionamiento es el siguiente; el termotanque tiene una bomba de agua que se activa cuando el nivel de agua es menor a 110 litros y la llena hasta el tope. También tiene una resistencia que hace lo mismo. Si la temperatura es menor a 45 grados se activa la resistencia dejándolo hasta la temperatura máxima. También se implementó una canilla que se abre cuando se termina de llenar y calentar el agua, dejando el nivel de agua en 50 litros. El uso de los LEDS del puerto b se utilizaron para hacer un seguimiento del funcionamiento y poder visualizarlo en el simulador.
