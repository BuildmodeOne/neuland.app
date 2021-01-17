import xmljs from 'xml-js'
import MemoryCache from '../../lib/memory-cache'

const CACHE_TTL = 60 * 60 * 1000
const URL_DE = 'https://www.max-manager.de/daten-extern/sw-erlangen-nuernberg/xml/mensa-ingolstadt.xml'
const URL_EN = 'https://www.max-manager.de/daten-extern/sw-erlangen-nuernberg/xml/en/mensa-ingolstadt.xml'

const cache = new MemoryCache({ ttl: CACHE_TTL })

function parseDataFromXml (xml) {
  const sourceData = xmljs.xml2js(xml, { compact: true })
  const now = new Date()

  let sourceDays = sourceData.speiseplan.tag
  if (!Array.isArray(sourceDays)) {
    sourceDays = [sourceDays]
  }

  const days = sourceDays.map(day => {
    const date = new Date(day._attributes.timestamp * 1000)

    if (now - date > 24 * 60 * 60 * 1000) {
      return null
    }

    let sourceItems = day.item
    if (!Array.isArray(sourceItems)) {
      sourceItems = [sourceItems]
    }

    const addInReg = /\s*\((.*?)\)\s*/
    const meals = sourceItems.map(item => {
      let text = item.title._text
      const allergenes = new Set()
      while (addInReg.test(text)) {
        const [addInText, addIn] = text.match(addInReg)
        text = text.replace(addInText, ' ')

        const newAllergenes = addIn.split(',')
        newAllergenes.forEach(newAll => allergenes.add(newAll))
      }

      const prices = [
        item.preis1._text,
        item.preis2._text,
        item.preis3._text
      ]
        .map(x => parseFloat(x.replace(',', '.')))

      return {
        name: text.trim(),
        prices,
        allergenes: [...allergenes]
      }
    })

    return {
      timestamp: date.toISOString(),
      meals
    }
  })

  return days.filter(x => x !== null)
}

async function fetchPlan (lang) {
  const url = (lang || 'de') === 'de' ? URL_DE : URL_EN

  let plan = cache.get(url)

  if (!plan) {
    const resp = await fetch(url)
    const body = await resp.text()
    plan = parseDataFromXml(body)

    cache.set(url, plan)
  }

  return plan
}

export default async function handler (req, res) {
  const plan = await fetchPlan(req.query.lang)

  res.statusCode = 200
  res.setHeader('Content-Type', 'application/json')
  res.end(JSON.stringify(plan))
}
