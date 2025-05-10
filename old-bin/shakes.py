#!/usr/bin/python
import requests
from BeautifulSoup import BeautifulSoup

url = 'http://www.pangloss.com/seidel/Shaker'
response = requests.get(url)
html = response.content

soup = BeautifulSoup(html)

quote = soup.find('p')

print quote.text


