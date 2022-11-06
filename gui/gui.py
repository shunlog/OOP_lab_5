#!/usr/bin/env python3
import PySimpleGUI as sg
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import matplotlib
import matplotlib.pyplot as plt
from numpy.random import rand
import pandas as pd
import json

def draw_figure(canvas, figure):
    figure_canvas_agg = FigureCanvasTkAgg(figure, canvas)
    figure_canvas_agg.draw()
    figure_canvas_agg.get_tk_widget().pack(side='top', fill='both', expand=1)
    return figure_canvas_agg

def draw_plot(fig_agg, ax):
    ax.cla()
    ax.grid(True)
    with open("test.json") as f:
        df = pd.read_json(f)
    print(df)
    ax.plot(df.index, df['profit'])
    # ax.legend()
    fig_agg.draw()

def get_fig_agg(canvas_elem):
    canvas = canvas_elem.TKCanvas
    # draw the intitial scatter plot
    fig = matplotlib.figure.Figure(figsize=(5, 4), dpi=90)
    ax = fig.add_subplot()
    ax.grid(True)
    fig_agg = draw_figure(canvas, fig)
    return fig_agg, fig, ax

def main():
    layout = [[[[sg.Button('Exit')], [sg.Button('Plot')]]],
              [[[sg.Canvas(key='-CANVAS1-')], [sg.Canvas(key='-CANVAS2-')]]]]

    window = sg.Window('Demo Application - Embedding Matplotlib In PySimpleGUI', layout, finalize=True)

    fig_agg, fig, ax = get_fig_agg(window['-CANVAS1-'])
    fig_agg2, fig2, ax2 = get_fig_agg(window[ '-CANVAS2-' ])

    while True:
        event, values = window.read()
        if event in (sg.WIN_CLOSED, 'Exit'):
            break
        elif event == 'Plot':
            draw_plot(fig_agg, ax)
            draw_plot(fig_agg2, ax2)
    window.close()


if __name__ == '__main__':
    main()
