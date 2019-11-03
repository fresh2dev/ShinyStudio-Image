#%% [markdown]

# Use VS code to author Python scripts and easily convert them to Jupyter notebooks.
# 
# Afterward, convert the Jupyter notebook (.ipynb) to HTML so it is viewable in Shiny Server.
# 
# `jupyter nbconvert *.ipynb --to html -y --template full`
# 
# See more: https://code.visualstudio.com/docs/python/jupyter-support

# This document is rendered on a schedule.

# To adjust the schedule, access Cronicle at http://*hostname*:8080

#%%

from datetime import datetime
 
print('Last rendered (UTC): ' + str(datetime.utcnow()))
