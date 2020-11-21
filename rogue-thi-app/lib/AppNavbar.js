import React from 'react'
import PropTypes from 'prop-types'

import Button from 'react-bootstrap/Button'
import Navbar from 'react-bootstrap/Navbar'

import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faChevronLeft } from '@fortawesome/free-solid-svg-icons'
import { useRouter } from 'next/router'

import styles from './AppNavbar.module.css'

export default function AppNavbar ({ title, showBack, children }) {
  const router = useRouter()

  if (typeof showBack === 'undefined') {
    showBack = true
  }

  function goBack () {
    router.back()
  }

  return (
    <Navbar sticky="top">
      <Navbar.Brand>
        {showBack && (
          <Button variant="link" onClick={() => goBack()}>
            <FontAwesomeIcon icon={faChevronLeft} />
            {' Zurück'}
          </Button>
        )}

        <Navbar.Brand className={styles.title}>
          {title}
        </Navbar.Brand>
      </Navbar.Brand>
    </Navbar>
  )
}
AppNavbar.propTypes = {
  title: PropTypes.string,
  showBack: PropTypes.bool,
  children: PropTypes.array
}