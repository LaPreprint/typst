#let orcidLogo(
  // The ORCID identifier with no URL, e.g. `0000-0000-0000-0000`
  orcid: none,
) = {
  /* Logos */
  let orcidSvg = ```<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 24 24"><path fill="#AECD54" d="M21.8,12c0,5.4-4.4,9.8-9.8,9.8S2.2,17.4,2.2,12S6.6,2.2,12,2.2S21.8,6.6,21.8,12z M8.2,5.8c-0.4,0-0.8,0.3-0.8,0.8s0.3,0.8,0.8,0.8S9,7,9,6.6S8.7,5.8,8.2,5.8z M10.5,15.4h1.2v-6c0,0-0.5,0,1.8,0s3.3,1.4,3.3,3s-1.5,3-3.3,3s-1.9,0-1.9,0H10.5v1.1H9V8.3H7.7v8.2h2.9c0,0-0.3,0,3,0s4.5-2.2,4.5-4.1s-1.2-4.1-4.3-4.1s-3.2,0-3.2,0L10.5,15.4z"/></svg>```.text

  if (orcid == none) {
    // Do not
    box(height: 1.1em, baseline: 13.5%, [#image.decode(orcidSvg)])
    return
  }

  link("https://orcid.org/" + orcid)[#box(height: 1.1em, baseline: 13.5%)[#image.decode(orcidSvg)]]
}

#let validateString(raw, name, alias: none) = {
  if (name in raw) {
    assert(type(raw.at(name)) == "string", message: name + " must be a string")
    return raw.at(name)
  }
  if (type(alias) != "array") {
    return
  }
  for a in alias {
    if (a in raw) {
      assert(type(raw.at(a)) == "string", message: a + " must be a string")
      return raw.at(a)
    }
  }
}

#let validateBoolean(raw, name, alias: none) = {
  if (name in raw) {
    assert(type(raw.at(name)) == "boolean", message: name + " must be a boolean")
    return raw.at(name)
  }
  if (type(alias) != "array") {
    return
  }
  for a in alias {
    if (a in raw) {
      assert(type(raw.at(a)) == "boolean", message: a + " must be a boolean")
      return raw.at(a)
    }
  }
}


#let validateAffiliation(raw) = {
  let out = (:)
  if (type(raw) == "string") {
    out.name = raw;
    return out;
  }
  let id = validateString(raw, "id")
  if (id != none) { out.id = id }
  let name = validateString(raw, "name")
  if (name != none) { out.name = name }
  let institution = validateString(raw, "institution")
  if (institution != none) { out.institution = institution }
  let department = validateString(raw, "department")
  if (department != none) { out.department = department }
  let doi = validateString(raw, "doi")
  if (doi != none) { out.doi = doi }
  let ror = validateString(raw, "ror")
  if (ror != none) { out.ror = ror }
  let address = validateString(raw, "address")
  if (address != none) { out.address = address }
  let city = validateString(raw, "city")
  if (city != none) { out.city = city }
  let region = validateString(raw, "region", alias: ("state", "province"))
  if (region != none) { out.region = region }
  let postal-code = validateString(raw, "postal-code", alias: ("postal_code", "postalCode", "zip_code", "zip-code", "zipcode", "zipCode"))
  if (postal-code != none) { out.postal-code = postal-code }
  let country = validateString(raw, "country")
  if (country != none) { out.country = country }
  let phone = validateString(raw, "phone")
  if (phone != none) { out.phone = phone }
  let fax = validateString(raw, "fax")
  if (fax != none) { out.fax = fax }
  let email = validateString(raw, "email")
  if (email != none) { out.email = email }
  let url = validateString(raw, "url")
  if (url != none) { out.url = url }
  let collaboration = validateBoolean(raw, "collaboration")
  if (collaboration != none) { out.collaboration = collaboration }
  return out;
}

#let pickAffiliationsObject(raw) = {
  if ("affiliation" in raw and "affiliations" in raw) {
    panic("You can only use `affiliation` or `affiliations`, not both")
  }
  if ("affiliation" in raw) {
    raw.affiliations = raw.affiliation
  }
  if ("affiliations" not in raw) { return; }
  if (type(raw.affiliations) == "string" or type(raw.affiliations) == "dictionary") {
    // convert to a list
    return (validateAffiliation(raw.affiliations),)
  } else if (type(raw.affiliations) == "array") {
    // validate each entry
    return raw.affiliations.map(validateAffiliation)
  } else {
    panic("The `affiliation` or `affiliations` must be a array, dictionary or string, got:", type(raw.affiliations))
  }
}


#let validateAuthor(raw) = {
  let out = (:)
  if (type(raw) == "string") {
    out.name = raw;
    return out;
  }
  let name = validateString(raw, "name")
  if (name != none) { out.name = name }
  let orcid = validateString(raw, "orcid")
  if (orcid != none) { out.orcid = orcid }
  let email = validateString(raw, "email")
  if (email != none) { out.email = email }
  let url = validateString(raw, "url")
  if (url != none) { out.url = url }

  let affiliations = pickAffiliationsObject(raw);
  if (affiliations != none) { out.affiliations = affiliations } else { out.affiliations = () }

  return out;
}

#let consolidateAffiliations(authors, affiliations) = {
  let cnt = 0
  for affiliation in affiliations {
    if ("id" not in affiliation) {
      affiliation.insert("id", "aff-" + str(cnt + 1))
    }
    affiliations.at(cnt) = affiliation
    cnt += 1
  }

  let authorCnt = 0
  for author in authors {
    let affCnt = 0
    for affiliation in author.affiliations {
      let pos = affiliations.position(item => { ("id" in item and item.id == affiliation.name) or ("name" in item and item.name == affiliation.name) })
      if (pos != none) {
        affiliation.remove("name")
        affiliation.id = affiliations.at(pos).id
        affiliations.at(pos) = affiliations.at(pos) + affiliation
      } else {
        affiliation.id = if ("id" in affiliation) { affiliation.id } else { affiliation.name }
        affiliations.push(affiliation)
      }
      author.affiliations.at(affCnt) = (id: affiliation.id)
      affCnt += 1
    }
    authors.at(authorCnt) = author
    authorCnt += 1
  }

  // Now that they are normalized, loop again and update the numbers
  let fullAffCnt = 0
  let authorCnt = 0
  for author in authors {
    let affCnt = 0
    for affiliation in author.affiliations {
      let pos = affiliations.position(item => { item.id == affiliation.id })
      let aff = affiliations.at(pos)
      if ("index" not in aff) {
        fullAffCnt += 1
        aff.index = fullAffCnt
        affiliations.at(pos) = affiliations.at(pos) + (index: fullAffCnt)
      }
      author.affiliations.at(affCnt) = (id: affiliation.id, index: aff.index)
      affCnt += 1
    }
    authors.at(authorCnt) = author
    authorCnt += 1
  }
  return (authors: authors, affiliations: affiliations)
}

#let loadFrontmatter(raw) = {
  let out = (:)
  let title = validateString(raw, "title")
  if (title != none) { out.title = title }
  let subtitle = validateString(raw, "subtitle")
  if (subtitle != none) { out.subtitle = subtitle }
  let short-title = validateString(raw, "short-title", alias: ("short_title", "shortTitle", "runningHead",))
  if (short-title != none) { out.short-title = short-title }

  // author information
  if ("author" in raw and "authors" in raw) {
    panic("You can only use `author` or `authors`, not both")
  }
  if ("author" in raw) {
    raw.authors = raw.author
  }
  if ("authors" in raw) {
    if (type(raw.authors) == "string" or type(raw.authors) == "dictionary") {
      // convert to a list
      out.authors = (validateAuthor(raw.authors),)
    } else if (type(raw.authors) == "array") {
      // validate each entry
      out.authors = raw.authors.map(validateAuthor)
    } else {
      panic("The `author` or `authors` must be a array, dictionary or string, got:", type(raw.authors))
    }
  }

  let affiliations = pickAffiliationsObject(raw);
  if (affiliations != none) { out.affiliations = affiliations } else { out.affiliations = () }

  let open-access = validateBoolean(raw, "open-access", alias: ("open_access", "openAccess",))
  if (open-access != none) { out.open-access = open-access }
  let doi = validateString(raw, "doi")
  if (doi != none) {
    assert(not doi.starts-with("http"), message: "DOIs should not include the link, use only the part after `https://doi.org/[]`")
    out.doi = doi
  }

  let date = none;
  let citation = validateString(raw, "citation")
  if (citation != none) {
    out.citation = citation;
  } else {
    // Create a citation, e.g. Cockett et al., 2023
    let year = if (date != none) { ", " + date.display("[year]") } else { ", " + datetime.today().display("[year]") }
    if (out.authors.len() == 1) {
      out.citation = out.authors.at(0).name.split(" ").last() + year
    } else if (out.authors.len() == 2) {
      out.citation = out.authors.at(0).name.split(" ").last() + " & " + out.authors.at(1).name.split(" ").last() + year
    } else if (out.authors.len() > 2) {
      out.citation = out.authors.at(0).name.split(" ").last() + " " + emph("et al.") + year
    }
  }

  let consolidated = consolidateAffiliations(out.authors, out.affiliations)
  out.authors = consolidated.authors
  out.affiliations = consolidated.affiliations

  return out
}
